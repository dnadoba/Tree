//
//  ViewController.swift
//  Tree macOS
//
//  Created by David Nadoba on 21.11.20.
//

import Cocoa
import Tree
import OutlineViewDiffableDataSource

extension BidirectionalCollection {
    subscript(safe i: Index) -> Element? {
        guard indices.contains(i) else { return nil }
        return self[i]
    }
}

final class NSItem<Value: Hashable>: NSObject, OutlineViewItem {
    var value: Value
    init(_ value: Value, hasChildren: Bool) {
        self.value = value
        self.hasChildren = hasChildren
        super.init()
    }
    @objc override var debugDescription: String { "NSItem(\(value))" }
    
    var hasChildren: Bool
    var isExpandable: Bool { true }
    
    /// Necessary for sets.
    override var hash: Int { value.hashValue }

    /// Necessary for outline view reloading.
    override func isEqual(_ object: Any?) -> Bool {
      guard let other = object as? Self else { return false }
      return other.value == value
    }
    
    func cellViewType(for tableColumn: NSTableColumn?) -> NSTableCellView.Type { MasterCellView.self }
}

// MARK: - Private API

final private class MasterCellView: NSTableCellView {

  /// Creates a cell with a label.
  init() {
    super.init(frame: .zero)

    let label = NSTextField(labelWithString: "")
    label.translatesAutoresizingMaskIntoConstraints = false
    label.lineBreakMode = .byTruncatingTail
    label.allowsExpansionToolTips = true
    label.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    label.setContentCompressionResistancePriority(.fittingSizeCompression, for: .horizontal)
    addSubview(label)

    self.textField = label
    self.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2),
      self.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 2),
      self.centerYAnchor.constraint(equalTo: label.centerYAnchor, constant: 1),
      self.heightAnchor.constraint(equalToConstant: 22),
    ])
  }

  @available(*, unavailable, message: "Use init")
  override init(frame frameRect: NSRect) {
    fatalError()
  }

  @available(*, unavailable, message: "Use init")
  required init?(coder: NSCoder) {
    fatalError()
  }

  // MARK: -

  /// Erases previous title.
  override func prepareForReuse() {
    super.prepareForReuse()

    if let label = textField {
      label.stringValue = ""
    }
  }

  /// Retrieves new title from the associated master item.
  override var objectValue: Any? {
    didSet {
      if let label = textField, let masterItem = objectValue as? NSItem<String> {
        label.stringValue = masterItem.value
      }
    }
  }
}

extension NSTableView {
    func removeAllTableColumns() {
        for tableColumn in tableColumns {
            removeTableColumn(tableColumn)
        }
    }
}

class TreeController: NSViewController {
    typealias Value = String
    typealias Item = NSItem<Value>
    var tree: TreeList = [TreeNode(
                            "A",
                            children: [
                                .init("AA"),
                                .init("AB"),
                                .init("AC", children: [
                                    .init("ACA"),
                                    .init("ACB"),
                                    .init("ACC"),
                                    .init("ACD", children: [
                                        .init("ACDA"),
                                        .init("ACDB"),
                                        .init("ACDC"),
                                    ]),
                                ]),
                                .init("AD"),
                            ])]
    var classCache: [Value: Item] = [:]
    var classTree: TreeList<Item> = .init()
    
    private let outlineView = NSOutlineView(frame: NSRect(origin: .zero, size: .init(width: 200, height: 400)))
    private let scrollView = NSScrollView()
    override func loadView() {
        scrollView.documentView = outlineView
        self.view = scrollView
    }
    static let nameColumn = NSUserInterfaceItemIdentifier(rawValue: "C1")
    override func viewDidLoad() {
        
        
        outlineView.removeAllTableColumns()
        let column = NSTableColumn(identifier: Self.nameColumn)
        column.title = "Name"
        column.dataCell = NSTextFieldCell()
        outlineView.addTableColumn(column)
        outlineView.allowsMultipleSelection = true
        outlineView.dataSource = dataSource
        
        modifyTree({ _ in })
        
    }
    /// Diffable data source similar to `NSCollectionViewDiffableDataSource`.
    private lazy var dataSource: OutlineViewDiffableDataSource = {
      let source = OutlineViewDiffableDataSource(outlineView: outlineView)
      source.draggingHandlers = OutlineViewDiffableDataSource.DraggingHandlers(validateDrop: { _, drop in

        // Option-, Control- and Command- modifiers are disabled
        guard drop.operation.contains(.move) else { return nil }

        // Dragging on, before and after self is denied
        guard drop.draggedItems.allSatisfy({ $0 !== drop.targetItem }) else { return nil }

        return drop
      }, acceptDrop: { sender, drop in
        
        let itemIndex = self.getTreeIndex(for: drop.targetItem)

        let sourceIndices = drop.draggedItems.map(self.getTreeIndex(for:)).sorted(by: <)
        self.modifyTree({
            var elements: [TreeNode<Value>] = []
            elements.reserveCapacity(sourceIndices.count)
            for index in sourceIndices.reversed() {
                elements.append($0.remove(at: index))
            }
            $0.insert(contentsOf: elements.reversed(), at: itemIndex)
        })
        return true
      })
      return source
    }()
    func updateClassTree(_ tree: TreeList<Value>) {
        classTree = tree.mapValuesWithNode { node in
            let value = node.value
            if classCache[value] == nil {
                classCache[value] = Item(value, hasChildren: !node.children.isEmpty)
            }
            return classCache[value]!
        }
    }
    var draggedItems: [Item] = []
    @objc func delete(_ sender: Any) {
        modifyTree({
            for index in getSelectedTreeIndices().sorted(by: <).reversed() {
                $0.remove(at: index)
            }
        })
    }
}

extension TreeController {
    func castToItem(_ item: Any) -> String {
        guard let id = (item as? Item)?.value else {
            fatalError("could not cast item \(item) to \(Item.self)")
        }
        return id
    }
    func getTreeIndex(for item: Any?) -> TreeIndex {
        guard let item = item else { return classTree.startIndex }
        let id = castToItem(item)
        return classTree.firstIndex(where: { $0.value.value == id })!
    }
    func getTreeNode(for item: Any) -> TreeNode<Item> {
        let id = castToItem(item)
        return classTree.first(where: { $0.value.value == id })!
    }
    func getSelectedTreeIndices() -> [TreeIndex] {
        return outlineView.selectedRowIndexes
            .compactMap(outlineView.item(atRow:))
            .map(getTreeIndex(for:))
    }
}

extension TreeController: NSOutlineViewDataSource {
    
    func makeSnapshot() -> DiffableDataSourceSnapshot {
        var snapshot = DiffableDataSourceSnapshot()
        for (index, item) in zip(classTree.indices, classTree) {
            let parent = classTree[safe: classTree.parentIndex(of: index)]
            snapshot.appendItems([item.value], into: parent?.value)
        }
        return snapshot
    }
    
    func modifyTree(_ modify: (inout TreeList<Value>) -> ()) {
        modify(&tree)
        updateClassTree(tree)
        dataSource.applySnapshot(makeSnapshot(), animatingDifferences: true)
    }
}


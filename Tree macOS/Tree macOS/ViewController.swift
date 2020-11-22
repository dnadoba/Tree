//
//  ViewController.swift
//  Tree macOS
//
//  Created by David Nadoba on 21.11.20.
//

import Cocoa
import Tree

extension BidirectionalCollection {
    subscript(safe i: Index) -> Element? {
        guard indices.contains(i) else { return nil }
        return self[i]
    }
}

final class NSItem<Value: Hashable>: NSObject {
    var value: Value
    init(_ value: Value) {
        self.value = value
        super.init()
    }
    @objc override var debugDescription: String { "NSItem(\(value))" }
    
    /// Necessary for sets.
    override var hash: Int { value.hashValue }

    /// Necessary for outline view reloading.
    override func isEqual(_ object: Any?) -> Bool {
      guard let other = object as? Self else { return false }
      return other.value == value
    }

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
        outlineView.delegate = self
        outlineView.dataSource = self
        
        modifyTree({ _ in })
        outlineView.registerForDraggedTypes([.string])
        
    }
    func updateClassTree(_ tree: TreeList<Value>) {
        classTree = tree.mapValues { value in
            if classCache[value] == nil {
                classCache[value] = Item(value)
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
extension TreeController: NSOutlineViewDelegate {
//    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
//        guard let id = (item as? Item)?.value else {
//            fatalError("could not cast item \(item) to \(Item.self)")
//        }
//        guard let value = tree.first(where: { $0.value == id }) else {
//            fatalError("item \(id) not in tree")
//        }
//        print(view)
//        let view = NSTableRowView()
//        return view
//    }
    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {
        let id = self.castToItem(item)
        return NSTextFieldCell(textCell: id)
    }
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return self.castToItem(item) as NSString
    }
}

extension TreeController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(castToItem(item), forType: .string)
        return pasteboardItem
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        getTreeNode(for: item).children.isEmpty == false
    }
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item else {
            return classTree.nodes.count
        }
        return getTreeNode(for: item).children.count
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let treeNodes: [TreeNode<Item>] = {
            guard let item = item else {
                return classTree.nodes
            }
            return getTreeNode(for: item).children
        }()
        return treeNodes[index].value
    }
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        self.draggedItems = draggedItems.map({ $0 as! Item })
    }
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        return .move
    }
    func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        
    }
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let itemIndex = getTreeIndex(for: item)
        let dropIndex: TreeIndex = {
            if index < 0 {
                return itemIndex
            } else {
                return tree.addChildIndex(index, to: itemIndex)
            }
        }()
        let sourceIndices = draggedItems.map(getTreeIndex(for:)).sorted(by: <)
        modifyTree({
            var elements: [TreeNode<Value>] = []
            elements.reserveCapacity(sourceIndices.count)
            for index in sourceIndices.reversed() {
                elements.append($0.remove(at: index))
            }
            $0.insert(contentsOf: elements.reversed(), at: dropIndex)
        })
        return true
    }
    
    func modifyTree(_ modify: (inout TreeList<Value>) -> ()) {
        modify(&tree)
        let oldTree = classTree
        updateClassTree(tree)
        let newTree = classTree
        let diff = newTree.difference(from: oldTree, by: { $0.value == $1.value })
            //.inferringMoves()
        print(diff)
        //outlineView.reloadData()
        outlineView.beginUpdates()
        for change in diff {
            switch change {
            case let .insert(offset, _, oldOffset):
                let newTreeIndex = newTree.index(newTree.startIndex, offsetBy: offset)
                let newChildIndex = newTree.childIndex(of: newTreeIndex)
                let newParent = newTree[safe: newTree.parentIndex(of: newTreeIndex)]?.value
                if let oldOffset = oldOffset {
                    let oldTreeIndex = oldTree.index(oldTree.startIndex, offsetBy: oldOffset)
                    let oldChildIndex = oldTree.childIndex(of: oldTreeIndex)
                    let oldParent = oldTree[safe: oldTree.parentIndex(of: oldTreeIndex)]?.value
                    outlineView.moveItem(at: oldChildIndex, inParent: oldParent, to: newChildIndex, inParent: newParent)
                } else {
                    outlineView.insertItems(at: [newChildIndex], inParent: newParent, withAnimation: [.effectFade, .slideDown])
                }
            case let .remove(offset, _, oldOffset):
                guard oldOffset == nil else { continue }
                let treeIndex = oldTree.index(oldTree.startIndex, offsetBy: offset)
                let childIndex = oldTree.childIndex(of: treeIndex)
                let parent = oldTree[safe: oldTree.parentIndex(of: treeIndex)]?.value
                print("remote item at \(treeIndex) ChildIndex: \(childIndex) Parent: \(parent?.value as Any) value: \(oldTree[treeIndex])")
                outlineView.removeItems(at: [childIndex], inParent: parent, withAnimation: [.effectFade, .slideDown])
            }
        }
        outlineView.endUpdates()
    }
}


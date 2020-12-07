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

extension NSTableView {
    func removeAllTableColumns() {
        for tableColumn in tableColumns {
            removeTableColumn(tableColumn)
        }
    }
}

class TreeController: NSViewController {
    typealias Value = String
    var tree: TreeList = [TreeNode(
                            "A",
                            children: [
                                .init("B"),
                                .init("C"),
                                .init("D", children: [
                                    .init("E"),
                                    .init("F"),
                                    .init("G"),
                                    .init("H", children: [
                                        .init("I"),
                                        .init("L"),
                                        .init("M"),
                                    ]),
                                ]),
                                .init("N"),
                            ])]
    
    private let outlineView = NSOutlineView(frame: NSRect(origin: .zero, size: .init(width: 200, height: 400)))
    private let scrollView = NSScrollView()
    override func loadView() {
        scrollView.documentView = outlineView
        self.view = scrollView
    }
    static let nameColumn = NSUserInterfaceItemIdentifier(rawValue: "C1")
    lazy var dataSource = OutlineViewTreeDataSource<Value>(outlineView: self.outlineView)
    var draggedItems: [Value] = []
    override func viewDidLoad() {
        outlineView.removeAllTableColumns()
        let column = NSTableColumn(identifier: Self.nameColumn)
        column.title = "Name"
        column.dataCell = NSTextFieldCell()
        outlineView.addTableColumn(column)
        outlineView.allowsMultipleSelection = true
        outlineView.delegate = self
        outlineView.registerForDraggedTypes([.string])
        
        
        dataSource.dataCell = { column, value in
            return NSTextFieldCell(textCell: value)
        }
        dataSource.objectForItem = { column, value in
            value as NSString
        }
        dataSource.isItemExpandable = { [unowned dataSource] item -> Bool in
            dataSource.getTreeNode(for: item)?.children.count != 0
        }
        
        dataSource.dragAndDrop = .init(draggingSessionWillBegin: { [weak self] (_, _, items) in
            self?.draggedItems = items
        }, pasteboardWriterForItem: { (item) -> NSPasteboardWriting? in
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(item, forType: .string)
            return pasteboardItem
        }, validateDrop: { (_, _, _) -> NSDragOperation in
            .move
        }, acceptDrop: { [unowned dataSource, weak self] (info, item, index) -> Bool in
            guard let self = self else { return false }
            let tree = dataSource.referenceTree
            let originalDropIndex: TreeIndex = {
                let itemIndex = dataSource.getTreeIndex(for: item)
                let index = index == NSOutlineViewDropOnItemIndex ? 0 : index
                return tree.addChildIndex(index, to: itemIndex)
            }()
            let originalParentDropIndex = tree.parentIndex(of: originalDropIndex)
            let originalChildDropIndex = tree.childIndex(of: originalDropIndex)
            let sourceIndices = self.draggedItems.map(dataSource.getTreeIndex(for:)).sorted(by: <)
            self.modifyTree({ treeSource in
                var tree = treeSource
                var childIndex = originalChildDropIndex
                var elements: [TreeNode<Value>] = []
                elements.reserveCapacity(sourceIndices.count)
                for index in sourceIndices.reversed() {
                    let currentParentIndex = tree.parentIndex(of: index)
                    let currentChildIndex = tree.childIndex(of: index)
                    if currentParentIndex == originalParentDropIndex &&
                        currentChildIndex < childIndex {
                        childIndex -= 1
                    }
                    elements.append(tree.remove(at: index))
                }
                func getTreeIndex(for item: Value?) -> TreeIndex? {
                    guard let item = item else { return TreeIndex(indices: []) }
                    return tree.firstIndex(where: { $0.value == item })
                }
                guard let itemIndex = getTreeIndex(for: item) else {
                    return
                }
                let dropIndex = tree.addChildIndex(childIndex, to: itemIndex)
                let childrenCountOfItem: Int? = {
                    if item == nil {
                        return tree.nodes.count
                    }
                    return tree[safe: itemIndex]?.children.count
                }()
                if let childrenCountOfItem = childrenCountOfItem,
                   childIndex >= 0, childIndex <= childrenCountOfItem {
                    tree.insert(contentsOf: elements.reversed(), at: dropIndex)
                    treeSource = tree
                }
            })
            return true
        }, draggingSessionEnded: { [weak self] _, _, _ in
            self?.draggedItems = []
        })
        
        modifyTree({ _ in })
        
        
    }
    @objc func delete(_ sender: Any) {
        modifyTree({
            for index in getSelectedTreeIndices().sorted(by: <).reversed() {
                $0.remove(at: index)
            }
        })
    }
}

extension TreeController {
    func getSelectedTreeIndices() -> [TreeIndex] {
        return outlineView.selectedRowIndexes
            .compactMap(outlineView.item(atRow:))
            .map({ dataSource.getTreeIndex(for: $0) })
    }
}
extension TreeController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return dataSource.getValueFromReference(item as Any) as NSString
    }
}

extension TreeController: NSOutlineViewDataSource {
    func modifyTree(_ modify: (inout TreeList<Value>) -> ()) {
        let treeCopy = tree
        undoManager?.registerUndo(withTarget: self, handler: { ctrl in
            ctrl.modifyTree({ $0 = treeCopy })
        })

        modify(&tree)
        dataSource.updateAndAnimatedChanges(tree)
    }
}


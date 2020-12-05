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
    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {
        let id = self.castToItem(item)
        return NSTextFieldCell(textCell: id)
    }
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return self.castToItem(item as Any) as NSString
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
        let originalDropIndex: TreeIndex = {
            let itemIndex = getTreeIndex(for: item)
            let index = index == NSOutlineViewDropOnItemIndex ? 0 : index
            return tree.addChildIndex(index, to: itemIndex)
        }()
        let originalParentDropIndex = tree.parentIndex(of: originalDropIndex)
        let originalChildDropIndex = tree.childIndex(of: originalDropIndex)
        let sourceIndices = draggedItems.map(getTreeIndex(for:)).sorted(by: <)
        modifyTree({ treeSource in
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
            func getTreeIndex(for item: Any?) -> TreeIndex? {
                guard let item = item else { return TreeIndex(indices: []) }
                let id = castToItem(item)
                return tree.firstIndex(where: { $0.value == id })
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
    }
    
    func modifyTree(_ modify: (inout TreeList<Value>) -> ()) {
        let treeCopy = tree
        undoManager?.registerUndo(withTarget: self, handler: { ctrl in
            ctrl.modifyTree({ $0 = treeCopy })
        })

        modify(&tree)
        let oldTree = classTree
        updateClassTree(tree)
        let newTree = classTree
        //outlineView.reloadData()
        let diff = newTree.difference(from: oldTree).inferringMoves()
        outlineView.animateChanges(diff)
        outlineView.expandNewSubtrees(old: oldTree, new: newTree)
    }
}

fileprivate extension TreeDifference {
    var isSingleMove: Bool {
        guard changes.count == 2 else { return false }
        guard case let .remove(_, _, insertPosition) = changes.first else { return false }
        return insertPosition != nil
    }
}

extension NSOutlineView {
    func animateChanges<Value: NSObject>(
        _ diff: TreeDifference<Value>,
        removeAnimation: NSTableView.AnimationOptions = [.effectFade, .slideUp],
        insertAnimation: NSTableView.AnimationOptions = [.effectFade, .slideDown]
    ) {
        beginUpdates()
        // currently, we can only safely animate a single move
        if diff.isSingleMove,
           case let .insert(newIndex, _, oldIndexOptional) = diff.changes.last,
           let oldIndex = oldIndexOptional {
            moveItem(at: oldIndex.offset, inParent: oldIndex.parent, to: newIndex.offset, inParent: newIndex.parent)
        } else {
            for change in diff.changes {
                switch change {
                case let .insert(newIndex, _, _):
                    insertItems(at: [newIndex.offset], inParent: newIndex.parent, withAnimation: [.effectFade, .slideUp])
                case let .remove(newIndex, _, _):
                    removeItems(at: [newIndex.offset], inParent: newIndex.parent, withAnimation: [.effectFade, .slideDown])
                }
            }
        }
        endUpdates()
    }
    func expandNewSubtrees<Value: NSObject>(old: TreeList<Value>, new: TreeList<Value>) {
        let newIsLeaf = Dictionary(uniqueKeysWithValues: new.mapChildrenWithParent({ ($0, $1.count == 0) }))
        let oldIsLeaf = Dictionary(uniqueKeysWithValues: old.mapChildrenWithParent({ ($0, $1.count == 0) }))
        for (item, isLeaf) in newIsLeaf {
            let wasLeaf = oldIsLeaf[item] ?? false
            if isLeaf != wasLeaf {
                reloadItem(item)
                if !isLeaf {
                    expandItem(item)
                }
            }
        }
    }
}


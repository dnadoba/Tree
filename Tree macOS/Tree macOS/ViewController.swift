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

public final class NSItem<Value: Hashable>: NSObject {
    public var value: Value
    public init(_ value: Value) {
        self.value = value
        super.init()
    }
    @objc public override var debugDescription: String { "NSItem(\(value))" }
    
    /// Necessary for sets.
    public override var hash: Int { value.hashValue }

    /// Necessary for outline view reloading.
    public override func isEqual(_ object: Any?) -> Bool {
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


public final class OutlineViewTreeDataSource<Item: Hashable>: NSObject, NSOutlineViewDataSource {
    public typealias ItemReference = NSItem<Item>
    public struct DragAndDrop {
        public var draggingSessionWillBegin: (NSDraggingSession, NSPoint, [Item]) -> () = { _, _, _ in }
        public var pasteboardWriterForItem: (Item) -> NSPasteboardWriting? = { _ in nil}
        public var updateDraggingItemsForDrag: (NSDraggingInfo) -> () = { _ in }
        public var validateDrop: (NSDraggingInfo, Item?, Int) -> NSDragOperation = { info, _, _ in info.draggingSourceOperationMask }
        public var acceptDrop: (NSDraggingInfo, Item?, Int) -> Bool = { _, _, _ in false }
        public var draggingSessionEnded: (NSDraggingSession, NSPoint, NSDragOperation) -> () = { _, _, _ in }
    }
    public let outlineView: NSOutlineView
    public var dataCell: (NSTableColumn?, Item) -> NSCell? = { _, _ in nil }
    public var objectForItem: (NSTableColumn?, Item) -> Any? = { _, _ in nil }
    public var isItemExpandable: (Item) -> Bool = { _ in false }
    public var dragAndDrop: DragAndDrop = DragAndDrop()
    
    private var referenceCache: [Item: ItemReference] = [:]
    private var indexCache: [Item: TreeIndex] = [:]
    public private(set) var referenceTree: TreeList<ItemReference> = []
    
    init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        super.init()
        outlineView.dataSource = self
    }
    
    public func updateAndAnimatedChanges(
        _ newTree: TreeList<Item>,
        expandNewSections: Bool = true
    ) {
        let oldTree = referenceTree
        updateReferenceTree(newTree)
        let newTree = referenceTree
        
        let diff = newTree.difference(from: oldTree).inferringMoves()
        outlineView.animateChanges(diff)
        outlineView.expandNewSubtrees(old: oldTree, new: newTree)
    }
    private func updateIndexCache(_ newTree: TreeList<Item>) {
        indexCache = .init(uniqueKeysWithValues: zip(newTree.lazy.map(\.value), newTree.indices))
    }
    private func updateReferenceTree(_ newTree: TreeList<Item>) {
        referenceTree = newTree.mapValues { item in
            if referenceCache[item] == nil {
                referenceCache[item] = ItemReference(item)
            }
            return referenceCache[item]!
        }
    }
    public func getTreeNode(for item: Item) -> TreeNode<ItemReference>? {
        referenceTree.first(where: { $0.value.value == item })
    }
    
    // MARK: Data Source
    func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? {
        dataCell(tableColumn, getValueFromReference(item))
    }
    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        isItemExpandable(getValueFromReference(item))
    }
    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item else {
            return referenceTree.nodes.count
        }
        return getTreeNode(for: item).children.count
    }
    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let treeNodes: [TreeNode<ItemReference>] = {
            guard let item = item else {
                return referenceTree.nodes
            }
            return getTreeNode(for: item).children
        }()
        return treeNodes[index].value
    }
    public func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        objectForItem(tableColumn, getValueFromReference(item as Any))
    }
    
    // MARK: Drag and Drop
    public func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItems draggedItems: [Any]) {
        dragAndDrop.draggingSessionWillBegin(session, screenPoint, draggedItems.map(getValueFromReference))
    }
    public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        dragAndDrop.pasteboardWriterForItem(getValueFromReference(item))
    }
    public func outlineView(_ outlineView: NSOutlineView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
        dragAndDrop.updateDraggingItemsForDrag(draggingInfo)
    }
    public func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        dragAndDrop.validateDrop(info, getValueFromReference(item), index)
    }
    public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        dragAndDrop.acceptDrop(info, getValueFromReference(item), index)
    }
    public func outlineView(_ outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        dragAndDrop.draggingSessionEnded(session, screenPoint, operation)
    }
}

extension OutlineViewTreeDataSource {
    public func getValueFromReference(_ referenceItem: Any) -> Item {
        guard let value = (referenceItem as? ItemReference)?.value else {
            fatalError("could not cast item \(referenceItem) to \(ItemReference.self)")
        }
        return value
    }
    public func getValueFromReference(_ item: Any?) -> Item? {
        (item as? ItemReference)?.value
    }
    public func getTreeIndex(for item: Any?) -> TreeIndex {
        getTreeIndex(for: getValueFromReference(item))
    }
    public func getTreeIndex(for item: Item?) -> TreeIndex {
        guard let item = item else { return referenceTree.startIndex }
        return indexCache[item]!
    }
    public func getTreeNode(for item: Any) -> TreeNode<ItemReference> {
        getTreeNode(for: getValueFromReference(item))
    }
    public func getTreeNode(for item: Item) -> TreeNode<ItemReference> {
        return referenceTree[getTreeIndex(for: item)]
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

extension NSOutlineView {
    func treeFromCurrentItems<Value: NSObject>() -> TreeList<Value> {
        return TreeList<Value>(getChildNodes(of: nil))
    }
    private func getChildNodes<Value: NSObject>(
        of item: Any?
    ) -> [TreeNode<Value>] {
        let childrenCount = self.numberOfChildren(ofItem: item)
        return (0..<childrenCount).map { index in
            let child = self.child(index, ofItem: item)
            return TreeNode(child as! Value, children: getChildNodes(of: child))
        }
    }
}


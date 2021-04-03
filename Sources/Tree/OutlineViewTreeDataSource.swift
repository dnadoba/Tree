//
//  OutlineViewTreeDataSource.swift
//  
//
//  Created by David Nadoba on 06.12.20.
//

#if os(macOS)
import AppKit

public final class ReferenceItem<Value: Hashable>: NSObject {
    public var value: Value
    public init(_ value: Value) {
        self.value = value
        super.init()
    }
    @objc public override var debugDescription: String { "ReferenceItem(\(value))" }
    
    /// Necessary for sets.
    public override var hash: Int { value.hashValue }

    /// Necessary for outline view reloading.
    public override func isEqual(_ object: Any?) -> Bool {
      guard let other = object as? Self else { return false }
      return other.value == value
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public final class OutlineViewTreeDataSource<Item: Hashable>: NSObject, NSOutlineViewDataSource {
    public typealias ItemReference = ReferenceItem<Item>
    public struct DragAndDrop {
        public var draggingSessionWillBegin: (NSDraggingSession, NSPoint, [Item]) -> () = { _, _, _ in }
        public var pasteboardWriterForItem: (Item) -> NSPasteboardWriting? = { _ in nil}
        public var updateDraggingItemsForDrag: (NSDraggingInfo) -> () = { _ in }
        public var validateDrop: (NSDraggingInfo, Item?, Int) -> NSDragOperation = { info, _, _ in info.draggingSourceOperationMask }
        public var acceptDrop: (NSDraggingInfo, Item?, Int) -> Bool = { _, _, _ in false }
        public var draggingSessionEnded: (NSDraggingSession, NSPoint, NSDragOperation) -> () = { _, _, _ in }
        public init(draggingSessionWillBegin: @escaping (NSDraggingSession, NSPoint, [Item]) -> () = { _, _, _ in }, pasteboardWriterForItem: @escaping (Item) -> NSPasteboardWriting? = { _ in nil}, updateDraggingItemsForDrag: @escaping (NSDraggingInfo) -> () = { _ in }, validateDrop: @escaping (NSDraggingInfo, Item?, Int) -> NSDragOperation = { info, _, _ in info.draggingSourceOperationMask }, acceptDrop: @escaping (NSDraggingInfo, Item?, Int) -> Bool = { _, _, _ in false }, draggingSessionEnded: @escaping (NSDraggingSession, NSPoint, NSDragOperation) -> () = { _, _, _ in }) {
            self.draggingSessionWillBegin = draggingSessionWillBegin
            self.pasteboardWriterForItem = pasteboardWriterForItem
            self.updateDraggingItemsForDrag = updateDraggingItemsForDrag
            self.validateDrop = validateDrop
            self.acceptDrop = acceptDrop
            self.draggingSessionEnded = draggingSessionEnded
        }
    }
    public let outlineView: NSOutlineView
    public var objectForItem: (NSTableColumn?, Item) -> Any? = { _, _ in nil }
    public var isItemExpandable: (Item) -> Bool = { _ in false }
    public var dragAndDrop: DragAndDrop = DragAndDrop()
    
    private var referenceCache: [Item: ItemReference] = [:]
    private var indexCache: [Item: TreeIndex] = [:]
    public private(set) var referenceTree: TreeList<ItemReference> = []
    
    public init(outlineView: NSOutlineView) {
        self.outlineView = outlineView
        super.init()
        outlineView.dataSource = self
    }
    
    public func updateAndAnimatedChanges(
        _ newTree: TreeList<Item>,
        removeAnimation: NSTableView.AnimationOptions = [.effectFade, .slideUp],
        insertAnimation: NSTableView.AnimationOptions = [.effectFade, .slideDown],
        expandNewSections: Bool = true
    ) {
        let oldTree = referenceTree
        updateIndexCache(newTree)
        updateReferenceTree(newTree)
        let newTree = referenceTree
        
        let diff = newTree.difference(from: oldTree).inferringMoves()
        outlineView.animateChanges(diff, removeAnimation: removeAnimation, insertAnimation: insertAnimation)
        if expandNewSections {
            outlineView.expandNewSubtrees(old: oldTree, new: newTree)
        }
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

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
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
        guard let item = item else { return TreeIndex(indices: []) }
        return indexCache[item]!
    }
    public func getTreeNode(for item: Any) -> TreeNode<ItemReference> {
        getTreeNode(for: getValueFromReference(item))
    }
    public func getTreeNode(for item: Item) -> TreeNode<ItemReference> {
        return referenceTree[getTreeIndex(for: item)]
    }
    public func getTreeIndex(for parent: Item?, childIndex index: Int) -> TreeIndex {
        let itemIndex = getTreeIndex(for: parent)
        let index = index == NSOutlineViewDropOnItemIndex ? 0 : index
        return referenceTree.addChildIndex(index, to: itemIndex)
    }
    public func getReference(for item: Item) -> Any? {
        referenceCache[item]
    }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension OutlineViewTreeDataSource {
    public func getSelectedTreeIndices() -> [TreeIndex] {
        return outlineView.selectedRowIndexes
            .compactMap(outlineView.item(atRow:))
            .map({ getTreeIndex(for: $0) })
    }
    public func getSelectedItems() -> [Item] {
        outlineView.selectedRowIndexes
            .compactMap({ getValueFromReference(outlineView.item(atRow: $0)) })
    }
}

#endif

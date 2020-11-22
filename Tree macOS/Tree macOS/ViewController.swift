//
//  ViewController.swift
//  Tree macOS
//
//  Created by David Nadoba on 21.11.20.
//

import Cocoa
import Tree

extension BidirectionalCollection {
    subscript(save i: Index) -> Element? {
        guard indices.contains(i) else { return nil }
        return self[i]
    }
}

final class NSItem<Value: Equatable>: NSObject {
    var value: Value
    init(_ value: Value) {
        self.value = value
        super.init()
    }
    @objc override var debugDescription: String { "NSItem(\(value))" }
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
        outlineView.reloadData()
        let diff = tree.difference(from: TreeList<Value>(),by: { $0.value == $1.value }).inferringMoves()
        applyDiffToClassTree(diff)
        
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
        var newTree = tree
        modify(&newTree)
        let diff = newTree.difference(from: tree, by: { $0.value == $1.value }).inferringMoves()
        print(diff)
        tree = newTree
        updateClassTree(tree)
        
    }
}


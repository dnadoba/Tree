//
//  ViewController.swift
//  Tree macOS
//
//  Created by David Nadoba on 21.11.20.
//

import Cocoa
import Tree

final class NSItem<Value: Equatable>: NSObject {
    var value: Value
    init(_ value: Value) {
        self.value = value
        super.init()
    }
    override func isEqual(to object: Any?) -> Bool {
        print("is equal called")
        guard let other = object as? NSItem<Value> else { return false }
        return value == other.value
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
    typealias Item = NSItem<String>
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
    override func loadView() {
        self.view = outlineView
    }
    static let nameColumn = NSUserInterfaceItemIdentifier(rawValue: "C1")
    override func viewDidLoad() {
        outlineView.removeAllTableColumns()
        let column = NSTableColumn(identifier: Self.nameColumn)
        column.title = "Name"
        column.dataCell = NSTextFieldCell()
        outlineView.addTableColumn(column)
        
        outlineView.delegate = self
        outlineView.dataSource = self
        
        
    }
}

extension TreeController {
    func castToItem(_ item: Any) -> String {
        guard let id = (item as? Item)?.value else {
            fatalError("could not cast item \(item) to \(Item.self)")
        }
        return id
    }
    func getTreeIndex(for item: Any) -> TreeIndex? {
        let id = castToItem(item)
        return tree.firstIndex(where: { $0.value == id })
    }
    func getTreeNode(for item: Any) -> TreeNode<String>? {
        let id = castToItem(item)
        return tree.first(where: { $0.value == id })
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
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        getTreeNode(for: item)?.children.isEmpty == false
    }
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item else {
            return tree.nodes.count
        }
        guard let id = (item as? Item)?.value else {
            fatalError("could not cast item \(item) to \(Item.self)")
        }
        return tree.first(where: { $0.value == id })?.children.count ?? 0
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let treeNodes: [TreeNode<String>] = {
            guard let item = item else {
                return tree.nodes
            }
            guard let id = (item as? Item)?.value else {
                fatalError("could not cast item \(item) to \(Item.self)")
            }
            return tree.first(where: { $0.value == id})?.children ?? []
        }()
        let node = treeNodes[index]
        return Item(node.value)
    }
}


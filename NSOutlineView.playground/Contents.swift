//: A Cocoa based Playground to present user interface

import AppKit
import PlaygroundSupport
import Tree

final class NSItem<Value: Equatable>: NSObject {
    var value: Value
    init(_ value: Value) {
        self.value = value
        super.init()
    }
    override func isEqual(to object: Any?) -> Bool {
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
    var tree = TreeList<String> {
        TreeNode("A") {
            "AA"
            "AB"
            TreeNode("AC") {
                "ACA"
                "ACB"
                "ACC"
                TreeNode("ACD") {
                    "ACDA"
                    "ACDB"
                    "ACDC"
                }
            }
            "AD"
        }
    }
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

extension TreeController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let id = (item as? Item)?.value else {
            fatalError("could not cast item \(item) to \(Item.self)")
        }
        guard let value = tree.first(where: { $0.value == id }) else {
            fatalError("item \(id) not in tree")
        }
        let view = NSTableRowView()
        return view
    }
}

extension TreeController: NSOutlineViewDataSource {
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

// Present the view in Playground
PlaygroundPage.current.liveView = TreeController()
PlaygroundPage.current.needsIndefiniteExecution = true



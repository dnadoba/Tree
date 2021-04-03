//
//  ViewController.swift
//  Tree macOS
//
//  Created by David Nadoba on 21.11.20.
//

import Cocoa
import Tree
import TreeUI

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
    var tree = TreeList<String> {
        TreeNode("A") {
            "B"
            "C"
            TreeNode("D") {
                "E"
                "F"
                "G"
                TreeNode("H") {
                    "I"
                    "L"
                    "M"
                }
            }
            "N"
        }
    }
    
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
        column.dataCell = NSTextFieldCell()
        
        outlineView.headerView = nil
        outlineView.addTableColumn(column)
        outlineView.style = .plain
        outlineView.rowHeight = 17
        outlineView.autoresizesOutlineColumn = false
        outlineView.intercellSpacing = .init(width: 3.0, height: 2.0)
        outlineView.allowsMultipleSelection = true
        outlineView.delegate = self
        outlineView.registerForDraggedTypes([.string])
        
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
            let originalDropIndex: TreeIndex = {
                let itemIndex = dataSource.getTreeIndex(for: item)
                let index = index == NSOutlineViewDropOnItemIndex ? 0 : index
                return dataSource.referenceTree.addChildIndex(index, to: itemIndex)
            }()
            let sourceIndices = self.draggedItems.map(dataSource.getTreeIndex(for:)).sorted(by: <)
            self.modifyTree({ treeSource in
                if let newTree = treeSource.move(indices: sourceIndices, to: originalDropIndex) {
                    treeSource = newTree
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
            $0.remove(at: dataSource.getSelectedTreeIndices())
        })
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


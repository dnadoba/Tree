//
//  OutlineView.swift
//  
//
//  Created by David Nadoba on 06.12.20.
//

#if os(macOS)
import AppKit

fileprivate extension TreeDifference {
    var isSingleMove: Bool {
        guard changes.count == 2 else { return false }
        guard case let .remove(_, _, insertPosition) = changes.first else { return false }
        return insertPosition != nil
    }
}

extension NSOutlineView {
    public func animateChanges<Value: NSObject>(
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
    public func expandNewSubtrees<Value: NSObject>(old: TreeList<Value>, new: TreeList<Value>) {
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
    /// Generates a tree by calling `numberOfChildren(ofItem:)` and `child(_:ofItem)` recursively
    /// This is especially useful for testing purposes.
    internal func treeFromCurrentItems<Value: NSObject>() -> TreeList<Value> {
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

#endif

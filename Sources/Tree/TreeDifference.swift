//
//  TreeDifference.swift
//  
//
//  Created by David Nadoba on 06.12.20.
//

import Foundation

public struct TreeDifference<Value: Hashable> {
    public struct Index: Equatable {
        public var parent: Value?
        public var depth: Int
        public var offset: Int
    }
    public enum Change: Equatable {
        case insert(index: Index, value: Value, associatedWith: Index?)
        case remove(index: Index, value: Value, associatedWith: Index?)
        internal var index: Index {
            get {
                switch self {
                case .insert(index: let i, value: _, associatedWith: _):
                    return i
                case .remove(index: let i, value: _, associatedWith: _):
                    return i
                }
            }
            set {
                switch self {
                case let .insert(_, value, associatedWith):
                    self = .insert(index: newValue, value: value, associatedWith: associatedWith)
                case let .remove(_, value, associatedWith):
                    self = .remove(index: newValue, value: value, associatedWith: associatedWith)
                }
            }
        }
        internal var value: Value {
            get {
                switch self {
                case .insert(index: _, value: let v, associatedWith: _):
                    return v
                case .remove(index: _, value: let v, associatedWith: _):
                    return v
                }
            }
        }
        internal var isInsert: Bool {
            guard case .insert = self else { return false }
            return true
        }
        internal var isRemove: Bool {
            guard case .remove = self else { return false }
            return true
        }
    }
    public var changes: [Change]
    public var insertions: [Change] { changes.filter { change in
        guard case .insert = change else { return false }
        return true
    } }
    public var removals: [Change] { changes.filter { change in
        guard case .remove = change else { return false }
        return true
    } }
    
    public init(changes: [Change]) {
        self.init(sortedChanges: changes.sorted { (a, b) -> Bool in
            switch (a, b) {
            case (.remove(_, _, _), .insert(_, _, _)):
                return true
            case (.insert(_, _, _), .remove(_, _, _)):
                return false
            case (.insert(_, _, _), .insert(_, _, _)):
                if a.index.depth == b.index.depth {
                    return a.index.offset < b.index.offset
                }
                return a.index.depth < b.index.depth
            case (.remove(_, _, _), .remove(_, _, _)):
                if b.index.depth == a.index.depth {
                    return b.index.offset < a.index.offset
                }
                return b.index.depth < a.index.depth
            }
        })
    }
    internal init(sortedChanges: [Change]) {
        self.changes = sortedChanges
    }
}

extension TreeDifference.Index: CustomDebugStringConvertible where Value: CustomDebugStringConvertible{
    public var debugDescription: String {
        "\(parent?.debugDescription ?? "nil") at \(offset) - depth: \(depth)"
    }
}

extension TreeDifference.Change: CustomDebugStringConvertible where Value: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .insert(index: index, value: value, associatedWith: associatedWith):
            return "insert(index: \(index), value: \(value.debugDescription), associatedWith: \(associatedWith?.debugDescription ?? "nil")"
        case let .remove(index: index, value: value, associatedWith: associatedWith):
            return "remove(index: \(index), value: \(value.debugDescription), associatedWith: \(associatedWith?.debugDescription ?? "nil")"
        }
    }
}


extension TreeList where Value: Hashable {
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    public func difference(from old: Self) -> TreeDifference<Value> {
        let new = self
        let mapNew = Dictionary(uniqueKeysWithValues: new.mapChildrenWithParents({
            ($0.last, (children: $1, depth: $0.count))
        }))
        let mapOld = Dictionary(uniqueKeysWithValues: old.mapChildrenWithParents({
            ($0.last, (children: $1, depth: $0.count))
        }))
        
        let keys = Set(mapNew.keys).union(mapOld.keys)
        
        let changes = keys.flatMap { parent -> [TreeDifference<Value>.Change] in
            /// if the `new` tree does not contain `parent`, all children get removed
            guard let new = mapNew[parent] else {
                /// if we are not at the root of the tree list, we can actually skip removing all children,
                /// because `parent` is a child of some other node and we will generate a remove operation
                /// for the parent or some ancestor.
                /// However, if we are at the root of the tree, parent is nil and we need to generate a remove for each child.
                guard parent != nil else {
                    return []
                }
                let old = mapOld[parent]! /// because `mapNew` does not contain `parent`, `mapOld` must contain it
                return old.children.enumerated().reversed().map { (offset, value) in
                    return .remove(
                        index: .init(parent: parent, depth: old.depth, offset: offset),
                        value: value,
                        associatedWith: nil
                    )
                }
            }
            /// if the `old` tree does not contain `parent`, all new children get inserted
            guard let old = mapOld[parent] else {
                return new.children.enumerated().map { (offset, value) in
                    return .insert(
                        index: .init(parent: parent, depth: new.depth, offset: offset),
                        value: value,
                        associatedWith: nil
                    )
                }
            }
            /// compute inserts and removes.
            return new.0.difference(from: old.0).map { change -> TreeDifference<Value>.Change in
                switch change {
                case let .insert(offset, value, _):
                    return .insert(
                        index: .init(parent: parent, depth: new.depth, offset: offset),
                        value: value,
                        associatedWith: nil
                    )
                case let .remove(offset, value, _):
                    return .remove(
                        index: .init(parent: parent, depth: old.depth, offset: offset),
                        value: value,
                        associatedWith: nil
                    )
                }
            }
        }
        return TreeDifference(changes: changes)
    }
}

extension TreeDifference {
    public func inferringMoves() -> TreeDifference<Value> {
        let removalMap = Dictionary(uniqueKeysWithValues: removals.map{ ($0.value, $0) })
        let insertionMap = Dictionary(uniqueKeysWithValues: insertions.map{ ($0.value, $0) })
        
        let changesWithInferredMoves = changes.map { change -> Change in
            switch change {
            case let .insert(index, value, _):
                return .insert(index: index, value: value, associatedWith: removalMap[value]?.index)
            case let .remove(index, value, _):
                return .remove(index: index, value: value, associatedWith: insertionMap[value]?.index)
            }
        }
        /// because we do not change the order of the changes, we do not need to sort the changes again
        return .init(sortedChanges: changesWithInferredMoves)
    }
}

extension TreeList where Value: Hashable {
    internal func firstIndex(of i: TreeDifference<Value>.Index) -> TreeIndex? {
        guard let treeIndex = i.parent.map({ parent in firstIndex(where: { $0.value ==  parent}) }) ?? TreeIndex(indices: []) else {
            return nil
        }
        return addChildIndex(i.offset, to: treeIndex)
    }
    public func applying(_ diff: TreeDifference<Value>) -> Self? {
        var tree = self
        var removedNodes = [Value:TreeNode<Value>]()
        for change in diff.changes {
            switch change {
            case let .remove(index, value, associatedWith):
                guard let treeIndex = tree.firstIndex(of: index) else {
                    return nil
                }
                if tree.indices.contains(treeIndex) {
                    let node = tree.remove(at: treeIndex)
                    if associatedWith != nil {
                        removedNodes[value] = node
                    }
                }
            case let .insert(destinationIndex, value, associatedWith):
                guard let destinationTreeIndex = tree.firstIndex(of: destinationIndex) else {
                    return nil
                }
                if associatedWith != nil {
                    guard let removedNode = removedNodes[value] else {
                        return nil
                    }
                    tree.insert(removedNode, at: destinationTreeIndex)
                } else {
                    tree.insert(TreeNode(value), at: destinationTreeIndex)
                }
            }
        }
        return tree
    }
}

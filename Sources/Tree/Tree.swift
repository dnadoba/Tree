//
//  Tree.swift
//
//
//  Created by David Nadoba on 06.12.20.
//

public struct TreeIndex {
    public typealias Slice = ArraySlice<Int>
    var indices: [Int]
    public init(indices: [Int]) {
        self.indices = indices
    }
}

extension TreeIndex: CustomDebugStringConvertible {
    public var debugDescription: String { indices.debugDescription }
}
extension TreeIndex: Comparable {
    public static func < (lhs: TreeIndex, rhs: TreeIndex) -> Bool {
        for (lhs, rhs) in zip(lhs.indices, rhs.indices) {
            if lhs == rhs {
                continue
            }
            return lhs < rhs
        }
        return lhs.indices.count < rhs.indices.count
    }
}

@dynamicMemberLookup
public struct TreeNode<Value> {
    public var value: Value
    public var children: [Self]
    public init(_ value: Value, children: [TreeNode<Value>] = []) {
        self.value = value
        self.children = children
    }
    subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
}

extension TreeNode: Equatable where Value: Equatable {}
extension TreeNode: Hashable where Value: Hashable {}

extension TreeNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        mapValuesWithParents({ parents, value in
            repeatElement("    ", count: parents.count).joined() + "\(value)"
        }).lazy.map({ $0.value }).joined(separator: "\n")
    }
}


extension TreeNode: MutableCollection, BidirectionalCollection {
    public typealias Element = TreeNode<Value>
    public typealias Index = TreeIndex
    public var startIndex: TreeIndex { TreeIndex(indices: []) }
    public var endIndex: TreeIndex { TreeIndex(indices: [children.count]) }
    public var count: Int { 1 + descendantCount }
    public var descendantCount: Int { children.reduce(0, { $0 + $1.count }) }
    public var underestimatedCount: Int { count }
    public subscript(position: TreeIndex) -> Element {
        get { self[position.indices[...]] }
        set { self[position.indices[...]] = newValue }
    }
        
        
    public subscript(position: TreeIndex.Slice) -> Element {
        get {
            if let index = position.first {
                return children[index][position.dropFirst()]
            } else {
                return self
            }
        }
        set {
            if let index = position.first {
                return children[index][position.dropFirst()] = newValue
            } else {
                self = newValue
            }
        }
        _modify {
            if let index = position.first {
                yield &children[index][position.dropFirst()]
            } else {
                yield &self
            }
        }
    }
    
    public func index(after i: TreeIndex) -> TreeIndex {
        self.index(after: i.indices[...]) ?? endIndex
    }
    fileprivate func index(after i: TreeIndex.Slice) -> TreeIndex? {
        if let index = i.first {
            if let nextIndex = children[index].index(after: i.dropFirst()) {
                return TreeIndex(indices: [index] + nextIndex.indices)
            } else {
                let nextIndex = index + 1
                if nextIndex >= children.endIndex {
                    return nil
                } else {
                    return TreeIndex(indices: [nextIndex])
                }
            }
        }
        if children.isEmpty {
            return nil
        } else {
            return TreeIndex(indices: [0])
        }
    }
    
    public func index(before i: TreeIndex) -> TreeIndex {
        self.index(before: i.indices[...])
    }
    fileprivate func index(before i: TreeIndex.Slice) -> TreeIndex {
        guard let index = i.first else { fatalError("invalid index \(i)") }
        if i.count == 1 {
            let nextIndex = index - 1
            if nextIndex < 0 {
                return TreeIndex(indices: [])
            } else {
                return TreeIndex(indices: [nextIndex] + (children[nextIndex].deepestLastChildIndex()?.indices ?? []))
            }
        }
        let nextTreeIndex = children[index].index(before: i.dropFirst())
        return TreeIndex(indices: [index] + nextTreeIndex.indices)
    }
    fileprivate func deepestLastChildIndex() -> TreeIndex? {
        if children.isEmpty {
            return nil
        }
        let lastChildIndex = children.index(before: children.endIndex)
        if let lastChildIndexTree = children[lastChildIndex].deepestLastChildIndex() {
            return TreeIndex(indices: [lastChildIndex] + lastChildIndexTree.indices)
        } else {
            return TreeIndex(indices: [lastChildIndex])
        }
    }
    
}

extension TreeNode {
    fileprivate mutating func remove(at i: TreeIndex.Slice) -> Element {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        guard i.count == 1 else {
            return children[index].remove(at: i.dropFirst())
        }
        return children.remove(at: index)
    }
    
    fileprivate mutating func insert<S>(contentsOf newElements: S, at i: TreeIndex.Slice) where S : Collection, Self.Element == S.Element {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        guard i.count == 1 else {
            children[index].insert(contentsOf: newElements, at: i.dropFirst())
            return
        }
        children.insert(contentsOf: newElements, at: index)
    }
}

extension TreeNode {
    public func parentIndex(of i: TreeIndex) -> TreeIndex {
        TreeIndex(indices: i.indices.dropLast())
    }
}

public struct TreeList<Value> {
    public var nodes: [TreeNode<Value>]
    public init(_ nodes: [TreeNode<Value>]) {
        self.nodes = nodes
    }
}

extension TreeList: Equatable where Value: Equatable {}
extension TreeList: Hashable where Value: Hashable {}

extension TreeList: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: TreeNode<Value>...) {
        self.init(elements)
    }
}

extension TreeList: MutableCollection, BidirectionalCollection {
    public typealias Element = TreeNode<Value>
    public typealias Index = TreeIndex
    public var startIndex: TreeIndex { TreeIndex(indices: [nodes.startIndex]) }
    public var endIndex: TreeIndex { TreeIndex(indices: [nodes.endIndex]) }
    public var count: Int { nodes.reduce(0, { $0 + $1.count }) }
    public var underestimatedCount: Int { count }
    public subscript(position: TreeIndex) -> Element {
        get { self[position.indices[...]] }
        set { self[position.indices[...]] = newValue }
    }
        
        
    fileprivate subscript(position: TreeIndex.Slice) -> Element {
        get {
            guard let index = position.first else {
                fatalError("invalid index \(position)")
            }
            return nodes[index][position.dropFirst()]
        }
        set {
            guard let index = position.first else {
                fatalError("invalid index \(position)")
            }
            nodes[index][position.dropFirst()] = newValue
        }
        // crashes the compiler
//        _modify {
//            guard let index = position.first else {
//                fatalError("invalid index \(position)")
//            }
//            yield &nodes[index][position.dropFirst()]
//        }
    }
    
    public func index(after i: TreeIndex) -> TreeIndex {
        self.index(after: i.indices[...]) ?? endIndex
    }
    fileprivate func index(after i: TreeIndex.Slice) -> TreeIndex? {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        if let nextIndex = nodes[index].index(after: i.dropFirst()) {
            return TreeIndex(indices: [index] + nextIndex.indices)
        } else {
            let nextIndex = index + 1
            return TreeIndex(indices: [nextIndex])
        }
    }
    public func index(before i: TreeIndex) -> TreeIndex {
        self.index(before: i.indices[...]) ?? endIndex
    }
    fileprivate func index(before i: TreeIndex.Slice) -> TreeIndex? {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        if i.count > 1 {
            let nextIndex = nodes[index].index(before: i.dropFirst())
            return TreeIndex(indices: [index] + nextIndex.indices)
        } else {
            let nextIndex = index - 1
            if let nextIndexTree = nodes[nextIndex].deepestLastChildIndex() {
                return TreeIndex(indices: [nextIndex] + nextIndexTree.indices)
            } else {
                return TreeIndex(indices: [nextIndex])
            }
        }
    }
}

extension TreeList {
    public init() {
        self.init([])
    }
    public mutating func remove<S>(at indices: S) where S: Sequence, S.Element == TreeIndex {
        indices
            .sorted(by: >)
            .forEach({ remove(at: $0) })
    }
    public mutating func removeSubrange(_ bounds: Range<TreeIndex>) {
        var index = bounds.upperBound
        while true {
            remove(at: index)
            if index == bounds.lowerBound {
                break
            } else {
                index = self.index(before: index)
            }
        }
    }
    @discardableResult
    public mutating func remove(at i: TreeIndex) -> Element {
        remove(at: i.indices[...])
    }
    fileprivate mutating func remove(at i: TreeIndex.Slice) -> Element {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        guard i.count == 1 else {
            return nodes[index].remove(at: i.dropFirst())
        }
        return nodes.remove(at: index)
    }

    public mutating func insert<S>(contentsOf newElements: S, at i: TreeIndex) where S : Collection, Self.Element == S.Element {
        insert(contentsOf: newElements, at: i.indices[...])
    }
    fileprivate mutating func insert<S>(contentsOf newElements: S, at i: TreeIndex.Slice) where S : Collection, Self.Element == S.Element {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        guard i.count == 1 else {
            nodes[index].insert(contentsOf: newElements, at: i.dropFirst())
            return
        }
        nodes.insert(contentsOf: newElements, at: index)
    }
}

extension TreeNode: CustomStringConvertible where Value: CustomStringConvertible {
    public var description: String {
        return mapValuesWithParents({ parents, value -> String in
            repeatElement("  ", count: parents.count).joined() + "- \(value.description)"
        }).map(\.value).joined(separator: "\n")
    }
}

extension TreeList: CustomStringConvertible where Value: CustomStringConvertible {
    public var description: String {
        return mapValuesWithParents({ parents, value -> String in
            repeatElement("  ", count: parents.count).joined() + "- \(value.description)"
        }).map(\.value).joined(separator: "\n")
    }
}

extension TreeList {
    public mutating func insert(_ element: TreeNode<Value>, at index: TreeIndex) {
        insert(contentsOf: CollectionOfOne(element), at: index)
    }
}

extension TreeList {
    public func depth(of i: TreeIndex) -> Int {
        i.indices.count - 1
    }
    public func parentIndex(of i: TreeIndex) -> TreeIndex {
        TreeIndex(indices: i.indices.dropLast())
    }
    public func childIndex(of i: TreeIndex) -> Int {
        i.indices.last!
    }
    public func addChildIndex(_ i: Int, to baseIndex: TreeIndex) -> TreeIndex {
        TreeIndex(indices: baseIndex.indices + [i])
    }
}

extension TreeList {
    public func neighbours(at i: TreeIndex) -> [TreeNode<Value>] {
        guard depth(of: i) > 0 else { return nodes }
        return self[parentIndex(of: i)].children
    }
    public func canInsert(at i: TreeIndex) -> Bool {
        let neighbours = self.neighbours(at: i)
        let childInsertIndex = self.childIndex(of: i)
        return (neighbours.startIndex...neighbours.endIndex).contains(childInsertIndex)
    }
}

extension TreeNode {
    public func mapValues<NewValue>(_ transform: (Value) -> NewValue) -> TreeNode<NewValue> {
        .init(transform(value), children: children.map { $0.mapValues(transform) })
    }
    public func mapValuesWithNode<NewValue>(_ transform: (TreeNode<Value>) -> NewValue) -> TreeNode<NewValue> {
        .init(transform(self), children: children.map { $0.mapValuesWithNode(transform) })
    }
    public func mapValuesWithParents<NewValue>(_ transform: ([Value], Value) -> NewValue) -> TreeNode<NewValue> {
        mapValuesWithParents(parents: [], transform)
    }
    fileprivate func mapValuesWithParents<NewValue>(
        parents: [Value],
        _ transform: ([Value], Value) -> NewValue
    ) -> TreeNode<NewValue> {
        let newParents = parents + CollectionOfOne(value)
        return .init(transform(parents, value),
                     children: children.map{ $0.mapValuesWithParents(parents: newParents, transform) })
    }
    fileprivate func mapChildrenWithParent<NewValue>(_ transform: (Value, [Value]) -> NewValue) -> [NewValue] {
        CollectionOfOne(transform(value, children.map{ $0.value })) +
            children.flatMap { $0.mapChildrenWithParent(transform) }
    }
    public func mapChildrenWithParents<NewValue>(
        _ transform: ([Value], [Value]) -> NewValue
    ) -> [NewValue] {
        self.mapChildrenWithParents(parents: [], transform)
    }
    fileprivate func mapChildrenWithParents<NewValue>(
        parents: [Value],
        _ transform: ([Value], [Value]) -> NewValue
    ) -> [NewValue] {
        let newParents = parents + CollectionOfOne(value)
        return CollectionOfOne(transform(newParents, children.map{ $0.value })) +
            children.flatMap{ $0.mapChildrenWithParents(parents: newParents, transform) }
    }
}

extension TreeList {
    public func mapValues<NewValue>(_ transform: (Value) -> NewValue) -> TreeList<NewValue> {
        .init(nodes.map({ $0.mapValues(transform) }))
    }
    public func mapValuesWithNode<NewValue>(_ transform: (TreeNode<Value>) -> NewValue) -> TreeList<NewValue> {
        .init(nodes.map({ $0.mapValuesWithNode(transform) }))
    }
    public func mapValuesWithParents<NewValue>(_ transform: ([Value], Value) -> NewValue) -> TreeList<NewValue> {
        .init(nodes.map({ $0.mapValuesWithParents(transform) }))
    }
    public func mapChildrenWithParent<NewValue>(_ transform: (Value?, [Value]) -> NewValue) -> [NewValue] {
        CollectionOfOne(transform(nil, nodes.map{ $0.value })) +
            nodes.flatMap { node in
                node.mapChildrenWithParent(transform)
            }
    }
    public func mapChildrenWithParents<NewValue>(
        _ transform: (_ parents: [Value], _ children: [Value]) -> NewValue
    ) -> [NewValue] {
        CollectionOfOne(transform([], nodes.map{ $0.value })) +
            nodes.flatMap { node in
                node.mapChildrenWithParents(transform)
            }
    }
}

// MARK: compactMap

extension TreeNode {
    public func compactMapValues<NewValue>(_ transform: (Value) -> NewValue?) -> TreeNode<NewValue>? {
        guard let newValue = transform(value) else { return nil }
        let newChildren = children.compactMap{ $0.compactMapValues(transform) }
        return .init(newValue, children: newChildren)
    }
}

extension TreeList {
    public func compactMapValues<NewValue>(_ transform: (Value) -> NewValue?) -> TreeList<NewValue> {
        let newNodes = nodes.compactMap({ $0.compactMapValues(transform) })
        return .init(newNodes)
    }
}

// MARK: filter

extension TreeNode {
    public func filterValues(_ isIncluded: (Value) -> Bool) -> TreeNode<Value>? {
        guard isIncluded(value) else { return nil }
        let newChildren = children.compactMap{ $0.filterValues(isIncluded) }
        return .init(value, children: newChildren)
    }
}

extension TreeList {
    public func filterValues(_ isIncluded: (Value) -> Bool) -> TreeList<Value> {
        let newNodes = nodes.compactMap({ $0.filterValues(isIncluded) })
        return .init(newNodes)
    }
}

// MARK: Move
extension TreeList where Value: Hashable {
    
    /// Moves the TreeNodes at the given `sourceIndices` to `insertIndex`.
    ///  The `sourceIndices` and `insertIndex` are both specified in the before state of the tree.
    ///  If elements are removed before the `insertIndex`, the `insertIndex` will be adjusted.
    ///
    ///  The move operation will fail and return nil, if the `insertIndex` is a child of one of the moved TreeNodes.
    /// - Parameters:
    ///   - sourceIndices: the indices of the elements that should be moved
    ///   - insertIndex: the insertion index to move the elements to
    /// - Returns: A new Tree with the specified changes or nil if the the move was not possible
    public func move(indices sourceIndices: [TreeIndex], to insertIndex: TreeIndex) -> TreeList<Value>? {
        var tree = self
        let originalParentInsertIndex = tree.parentIndex(of: insertIndex)
        let originalChildInsertIndex = tree.childIndex(of: insertIndex)
        
        let parent = tree[safe: originalParentInsertIndex]?.value
    
        let sourceIndices = sourceIndices.sorted(by: <)

        var childIndex = originalChildInsertIndex
        var elements: [TreeNode<Value>] = []
        elements.reserveCapacity(sourceIndices.count)
        for index in sourceIndices.reversed() {
            let currentParentIndex = tree.parentIndex(of: index)
            let currentChildIndex = tree.childIndex(of: index)
            if currentParentIndex == originalParentInsertIndex &&
                currentChildIndex < childIndex {
                childIndex -= 1
            }
            elements.append(tree.remove(at: index))
        }
        func getTreeIndex(for item: Value?) -> TreeIndex? {
            guard let item = item else { return TreeIndex(indices: []) }
            return tree.firstIndex(where: { $0.value == item })
        }
        guard let parentIndex = getTreeIndex(for: parent) else {
            return nil
        }
        let dropIndex = tree.addChildIndex(childIndex, to: parentIndex)
        let childrenCountOfItem: Int? = {
            if parent == nil {
                return tree.nodes.count
            }
            return tree[safe: parentIndex]?.children.count
        }()
        if let childrenCountOfItem = childrenCountOfItem,
           childIndex >= 0, childIndex <= childrenCountOfItem {
            tree.insert(contentsOf: elements.reversed(), at: dropIndex)
            return tree
        } else {
            return nil
        }
    }
}

extension MutableCollection {
    fileprivate mutating func mapInPlace(_ transform: (inout Element) -> ()) {
        for index in indices {
            transform(&self[index])
        }
    }
}

extension TreeNode {
    public mutating func removeAllChildren(where shouldBeRemoved: (TreeNode<Value>) -> Bool) {
        children.removeAll(where: shouldBeRemoved)
        children.mapInPlace {
            $0.removeAllChildren(where: shouldBeRemoved)
        }
    }
}

extension TreeList {
    public mutating func removeAll(where shouldBeRemoved: (TreeNode<Value>) -> Bool) {
        nodes.removeAll(where: shouldBeRemoved)
        nodes.mapInPlace {
            $0.removeAllChildren(where: shouldBeRemoved)
        }
    }
}

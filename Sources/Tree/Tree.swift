
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

public struct TreeNode<Value> {
    public var value: Value
    public var children: [Self]
    public init(_ value: Value, children: [TreeNode<Value>] = []) {
        self.value = value
        self.children = children
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
    public mutating func removeSubrange(_ bounds: Range<TreeIndex>) {
        var indicies = [TreeIndex]()
        var index = bounds.lowerBound

        while index < bounds.upperBound {
            indicies.append(index)
            index = self.index(after: index)
        }
        for index in indicies.reversed() {
            remove(at: index)
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

extension TreeList {
    public mutating func insert(_ element: TreeNode<Value>, at index: TreeIndex) {
        insert(contentsOf: CollectionOfOne(element), at: index)
    }
}

extension TreeList {
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
}


struct TreeIndex {
    typealias Slice = ArraySlice<Int>
    var indices: [Int]
}

extension TreeIndex: CustomDebugStringConvertible {
    var debugDescription: String { indices.debugDescription }
}
extension TreeIndex: Comparable {
    static func < (lhs: TreeIndex, rhs: TreeIndex) -> Bool {
        for (lhs, rhs) in zip(lhs.indices, rhs.indices) {
            if lhs == rhs {
                continue
            }
            return lhs < rhs
        }
        return lhs.indices.count < rhs.indices.count
    }
}

struct TreeNode<Value> {
    var value: Value
    var children: [Self]
    internal init(_ value: Value, children: [TreeNode<Value>] = []) {
        self.value = value
        self.children = children
    }
}

extension TreeNode: Equatable where Value: Equatable {}
extension TreeNode: Hashable where Value: Hashable {}


extension TreeNode: MutableCollection {
    typealias Index = TreeIndex
    var startIndex: TreeIndex { TreeIndex(indices: []) }
    var endIndex: TreeIndex { TreeIndex(indices: [children.count]) }
    subscript(position: TreeIndex) -> Value {
        get { self[position.indices[...]] }
        set { self[position.indices[...]] = newValue }
    }
        
        
    subscript(position: TreeIndex.Slice) -> Value {
        get {
            if let index = position.first {
                return children[index][position.dropFirst()]
            } else {
                return value
            }
        }
        set {
            if let index = position.first {
                return children[index][position.dropFirst()] = newValue
            } else {
                self.value = newValue
            }
        }
        _modify {
            if let index = position.first {
                yield &children[index][position.dropFirst()]
            } else {
                yield &value
            }
        }
    }
    
    func index(after i: TreeIndex) -> TreeIndex {
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
}

extension TreeNode {
    fileprivate mutating func remove(at i: TreeIndex.Slice) -> Value {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        guard i.count == 1 else {
            return children[index].remove(at: i.dropFirst())
        }
        return children.remove(at: index).value
    }
    
    fileprivate mutating func insert<S>(contentsOf newElements: S, at i: TreeIndex.Slice) where S : Collection, Self.Element == S.Element {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        guard i.count == 1 else {
            children[index].insert(contentsOf: newElements, at: i.dropFirst())
            return
        }
        children.insert(contentsOf: newElements.map{ TreeNode($0) }, at: index)
    }
}

struct TreeRoot<Value> {
    var nodes: [TreeNode<Value>]
    init(_ nodes: [TreeNode<Value>]) {
        self.nodes = nodes
    }
}

extension TreeRoot: Equatable where Value: Equatable {}
extension TreeRoot: Hashable where Value: Hashable {}

extension TreeRoot: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: TreeNode<Value>...) {
        self.init(elements)
    }
}

extension TreeRoot: MutableCollection {
    typealias Index = TreeIndex
    var startIndex: TreeIndex { TreeIndex(indices: [nodes.startIndex]) }
    var endIndex: TreeIndex { TreeIndex(indices: [nodes.endIndex]) }
    subscript(position: TreeIndex) -> Value {
        get { self[position.indices[...]] }
        set { self[position.indices[...]] = newValue }
    }
        
        
    fileprivate subscript(position: TreeIndex.Slice) -> Value {
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
    
    func index(after i: TreeIndex) -> TreeIndex {
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
}

extension TreeRoot: RangeReplaceableCollection {
    init() {
        self.init([])
    }
    mutating func removeSubrange(_ bounds: Range<TreeIndex>) {
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
    mutating func remove(at i: TreeIndex) -> Value {
        remove(at: i.indices[...])
    }
    fileprivate mutating func remove(at i: TreeIndex.Slice) -> Value {
        guard let index = i.first else {
            fatalError("invalid index \(i)")
        }
        guard i.count == 1 else {
            return nodes[index].remove(at: i.dropFirst())
        }
        return nodes.remove(at: index).value
    }

    mutating func insert<S>(contentsOf newElements: S, at i: TreeIndex) where S : Collection, Self.Element == S.Element {
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
        nodes.insert(contentsOf: newElements.map{ TreeNode($0) }, at: index)
    }

    mutating func replaceSubrange<C>(_ subrange: Range<TreeIndex>, with newElements: C) where C : Collection, Self.Element == C.Element {
        removeSubrange(subrange)
        insert(contentsOf: newElements, at: subrange.lowerBound)
    }
}

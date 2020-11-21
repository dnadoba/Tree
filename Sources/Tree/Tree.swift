
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
    var value: Value?
    var children: [Self]
    internal init(_ value: Value, children: [TreeNode<Value>] = []) {
        self.value = value
        self.children = children
    }
}


extension TreeNode: MutableCollection {
    typealias Index = TreeIndex
    var startIndex: TreeIndex { TreeIndex(indices: []) }
    var endIndex: TreeIndex {
        if value == nil {
            return TreeIndex(indices: [])
        } else {
            return TreeIndex(indices: [children.count])
        }
    }
    subscript(position: TreeIndex) -> Value {
        get { self[position.indices[...]] }
        set { self[position.indices[...]] = newValue }
    }
        
        
    fileprivate subscript(position: TreeIndex.Slice) -> Value {
        get {
            if let index = position.first {
                return children[index][position.dropFirst()]
            } else {
                return value!
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
                yield &value!
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

extension TreeNode: RangeReplaceableCollection {
    init() {
        self.value = nil
        self.children = []
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
        if i.count == 0 {
            defer { value = nil }
            return value!
        }
        if i.count == 1, let index = i.first {
            return children.remove(at: index).value!
        }
        return remove(at: i.dropFirst())
    }
    
    mutating func insert<S>(contentsOf newElements: S, at i: TreeIndex) where S : Collection, Self.Element == S.Element {
        insert(contentsOf: newElements, at: i.indices[...])
    }
    fileprivate mutating func insert<S>(contentsOf newElements: S, at i: TreeIndex.Slice) where S : Collection, Self.Element == S.Element {
        guard let index = i.first else {
            if value == nil {
                if let newValue = newElements.first {
                    value = newValue
                }
                children.insert(contentsOf: newElements.dropFirst().map{ TreeNode($0) }, at: 0)
            } else {
                children.insert(contentsOf: newElements.map{ TreeNode($0) }, at: 0)
            }
            return
        }
        if i.count == 1 {
            children.insert(contentsOf: newElements.dropFirst().map{ TreeNode($0) }, at: index)
        }
        return children[index].insert(contentsOf: newElements, at: i.dropFirst())
    }
    
    mutating func replaceSubrange<C>(_ subrange: Range<TreeIndex>, with newElements: C) where C : Collection, Self.Element == C.Element {
        removeSubrange(subrange)
        insert(contentsOf: newElements, at: subrange.lowerBound)
    }
}

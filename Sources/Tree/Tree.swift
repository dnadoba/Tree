
struct Tree {
    
}

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


extension TreeNode: MutableCollection {
    typealias Index = TreeIndex
    var startIndex: TreeIndex { TreeIndex(indices: []) }
    var endIndex: TreeIndex { TreeIndex(indices: [children.count]) }
    subscript(position: TreeIndex) -> Value {
        get { self[position.indices[...]] }
        set { self[position.indices[...]] = newValue }
    }
        
        
    fileprivate subscript(position: TreeIndex.Slice) -> Value {
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


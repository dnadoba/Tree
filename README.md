# Tree - general tree data structure, tree diffing, NSOutlineView and SwiftUI support
This package primarily includes a general tree data structure. 
It also includes a tree diffing algorithm and `OutlineViewTreeDataSource` that allows to use Swift value types with `NSOutlineView` 
A demo App can be found in the `Tree macOS` folder and the `NSOutlineView` Playground with support for drag and drop, undo/redo and animations.

`TreeNode` and `TreeList` can also be used as a model for `OutlineGroup` in SwiftUI applications. To see it in action, take a look at the `SwiftUI-iOS` or `SwiftUI-macOS` Playground. 

### `TreeNode`
 `TreeNode` is a general tree data structure implementation as a value type.
 Each `TreeNode` has a `value` and 0 or more `children`. It is actually just a struct which holds a value and an array of child nodes:
 
 ```swift
 struct TreeNode<Value> {
 	var value: Value
 	var children: [TreeNode<Value>]
 }
 ```
 With the help of `@resultBuilder` you can create a `TreeNode` like this:
 > Note: `@resultBuilder` requires Swift 5.4 or higher (e.g. Xcode 12.5)

```swift
let treeNode = TreeNode("root node") {
    "child 1"
    "child 2"
    TreeNode("child 3") {
        "child of child 3"
    }
    "child 4"
}
print(treeNode)
//  - root node
//    - child 1
//    - child 2
//    - child 3
//      - child of child 3
//    - child 4
```
### `TreeList` - a list of `TreeNode`s
 `TreeList` is a list of `TreeNode`s, which enables multiple nodes to be at level 0.
  In addition, `TreeList` conforms to `MutableCollection` and `BidirectionalCollection` which enables a ton of useful algorithms.

```swift
let treeList = TreeList<String> {
    "root 1"
    "root 2"
    TreeNode("root 3") {
        "child of root 3"
    }
    "root 4"
}
print(treeList)
//  - root 1
//  - root 2
//  - root 3
//      - child of root 3
//  - root 4
```
### additional methods
 `TreeNode` and `TreeList` have a similar API.
 They both support special map, compactMap and filter operations:
 
 ```swift
 extension TreeNode {
     func mapValues<NewValue>(_ transform: (Value) -> NewValue) -> TreeNode<NewValue>
     func mapValuesWithNode<NewValue>(_ transform: (TreeNode<Value>) -> NewValue) -> TreeNode<NewValue>
     func mapValuesWithParents<NewValue>(_ transform: ([Value], Value) -> NewValue) -> TreeNode<NewValue>
     func mapChildrenWithParents<NewValue>(_ transform: ([Value], [Value]) -> NewValue) -> [NewValue]
 
     func compactMapValues<NewValue>(_ transform: (Value) -> NewValue?) -> TreeNode<NewValue>?
 
     func filterValues(_ isIncluded: (Value) -> Bool) -> TreeNode<Value>
 }
 ```
 
 In addition, they support moving nodes which is useful for implementing drag and drop:
 
 ```swift
 extension TreeList where Value : Hashable {
     /// Moves the TreeNodes at the given `sourceIndices` to `insertIndex`.
     ///  The `sourceIndices` and `insertIndex` are both specified in the before state of the tree.
     ///  If elements are removed before the `insertIndex`, the `insertIndex` will be adjusted.
     ///
     ///  The move operation will fail and return nil, if the `insertIndex` is a child of one of the moved TreeNodes.
     /// - Parameters:
     ///   - sourceIndices: the indices of the elements that should be moved
     ///   - insertIndex: the insertion index to move the elements to
     /// - Returns: A new Tree with the specified changes or nil if the the move was not possible
     public func move(indices sourceIndices: [TreeIndex], to insertIndex: TreeIndex) -> TreeList<Value>?
 }
 ```

### `NSOutlineView`
> Note: `OutlineViewTreeDataSource` is defined in a seperate module called `TreeUI`. You need to `import TreeUI` to use it.

 `TreeList` and `TreeNode` were originaly created to be used as data model for NSOutlineView. Therefore, this package includes a tree diffing algorithm and `OutlineViewTreeDataSource` that allows to use Swift value types with `NSOutlineView`. Take a look at NSOutlineView Playground or the Tree macOS example Xcode project which are part of this repository.
 The diffing algorithm can also be used to efficiently send only what has changed over the network to another peer/server.
 

### SwiftUI
 `TreeNode` and `TreeList` can be used with SwiftUI as well.

```swift
import SwiftUI
extension TreeNode {
    var optionalChildren: [TreeNode<Value>]? {
        children.isEmpty ? nil : children
    }
}
struct ContentView: View {
    @State var tree: TreeList<String>
    
    var body: some View {
        List(tree.nodes, id: \.value, children: \.optionalChildren) { node in
            Text(node.value)
        }
    }
}
```
For a full example take a look into the SwiftUI-iOS or SwiftUI-macOS Playground.

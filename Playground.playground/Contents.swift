import Tree

/**
 `TreeNode` is a general tree data structure implementation.
 Each `TreeNode` has a `Value` and 0 or more `children`.
 With the help of `@resultBuilder` you can create a `TreeNode` like this:
*/

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

/**
 `TreeList` is a list of `TreeNode`s, which enables multiple nodes to be at level 0.
  In addition, `TreeList` conforms to `MutableCollection` and `BidirectionalCollection` which enables a ton of useful algorithms.
*/
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

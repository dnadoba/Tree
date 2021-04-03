import SwiftUI
import PlaygroundSupport
import Tree

extension TreeNode {
    var optionalChildren: [TreeNode<Value>]? {
        children.isEmpty ? nil : children
    }
}

struct ContentView: View {
    @State var tree = TreeList<String> {
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
    
    var body: some View {
        List(tree.nodes, id: \.value, children: \.optionalChildren) { node in
            Text(node.value)
        }
    }
}

PlaygroundPage.current.setLiveView(ContentView())


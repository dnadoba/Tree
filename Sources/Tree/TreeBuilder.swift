//
//  TreeBuilder.swift
//  
//
//  Created by David Nadoba on 03.04.21.
//
#if swift(>=5.4)
@resultBuilder
public struct TreeBuilder<Value> {
    // We'll use these typealiases to make the lifting rules clearer in this example.
    // Result builders don't really require these to be specific types that can
    // be named this way!  For example, Expression could be "either a String or an
    // HTMLNode", and we could just overload buildExpression to accept either.
    // Similarly, Component could be "any Collection of HTML", and we'd just have
    // to make buildBlock et al generic functions to support that.  But we'll keep
    // it simple so that we can write these typealiases.
    
    // Expression-statements in the DSL should always produce an HTML value.
    public typealias Expression = TreeNode<Value>
    
    // "Internally" to the DSL, we'll just build up flattened arrays of HTML
    // values, immediately flattening any optionality or nested array structure.
    public typealias Component = [TreeNode<Value>]
    
    
    // support raw values as an expression
    @_disfavoredOverload
    public static func buildExpression(_ expression: Value) -> Component {
        [.init(expression)]
    }
    
    // Given an expression result, "lift" it into a Component.
    //
    // If Component were "any Collection of HTML", we could have this return
    // CollectionOfOne to avoid an array allocation.
    public static func buildExpression(_ expression: Expression) -> Component {
        return [expression]
    }
    
    // Build a combined result from a list of partial results by concatenating.
    //
    // If Component were "any Collection of HTML", we could avoid some unnecessary
    // reallocation work here by just calling joined().
    public static func buildBlock(_ children: Component...) -> Component {
        children.flatMap { $0 }
    }
    
    // We can provide this overload as a micro-optimization for the common case
    // where there's only one partial result in a block.  This shows the flexibility
    // of using an ad-hoc builder pattern.
    public static func buildBlock(_ component: Component) -> Component {
        component
    }
    
    // Handle optionality by turning nil into the empty list.
    public static func buildOptional(_ children: Component?) -> Component {
        children ?? []
    }
    
    // Handle optionally-executed blocks.
    public static func buildEither(first child: Component) -> Component {
        child
    }
    
    // Handle optionally-executed blocks.
    public static func buildEither(second child: Component) -> Component {
        child
    }
}

extension TreeList {
    public init(@TreeBuilder<Value> children: () -> [TreeNode<Value>]) {
        self.init(children())
    }
}
extension TreeNode {
    public init(_ value: Value, @TreeBuilder<Value> children: () -> [TreeNode<Value>]) {
        self.init(value, children: children())
    }
}
#endif

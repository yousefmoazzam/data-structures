const std = @import("std");

const list = @import("linked_list.zig");
const stack = @import("stack.zig");

/// Perform inorder traversal of binary tree via recursion
fn inorder(allocator: std.mem.Allocator, current_node: ?*Node, index_stack: *stack.Stack, visited_nodes: *list.SinglyLinkedList(*Node)) std.mem.Allocator.Error!void {
    const node = if (current_node) |val| val else {
        return;
    };

    try index_stack.*.push(allocator, node.*.value);

    // If the left child of current node is not null, keep traversing down the left subtree
    if (node.*.left) |left_child| {
        try inorder(allocator, left_child, index_stack, visited_nodes);
    }

    // If execution has reached here, then either the left child was null, or we have returned
    // from a recursive call that occurred in the above `if` statement.
    //
    // In either case, we must now pop off the current value and then note this index/node as
    // the next to be visited.
    if (index_stack.*.pop(allocator)) |_| {} else |_| {
        // If the algorithm is correct, an empty stack should never attempted to be popped.
        // Hence, unreachable.
        unreachable;
    }
    try visited_nodes.append(allocator, node);

    // Now need to explore right subtree, so check if the right child index is null or not, and
    // recurse down it if not
    if (node.*.right) |right_child| {
        try inorder(allocator, right_child, index_stack, visited_nodes);
    }
}

/// Provides a slice of `u8` pointers in the order of traversal, where the traversal operations
/// have been eagerly evaluated to produce the slice
pub const InorderTraversalEagerIterator = struct {
    nodes: *list.SinglyLinkedList(*Node),
    allocator: std.mem.Allocator,
    current: usize,

    pub fn next(self: *InorderTraversalEagerIterator) ?u8 {
        if (self.current < self.nodes.*.len) {
            const val = if (self.nodes.get(self.current)) |node| node.*.value else |_| {
                // The `self.current` value starts at 0 and is incremented for each call to
                // `next()`. The `if` body only is executed if the `self.current` value is
                // within the bounds of the linked list, so
                // `SinglyLinkedList(Node).get(self.current)` should never return an
                // `OutOfBounds` error. Hence, unreachable.
                unreachable;
            };
            self.current += 1;
            return val;
        }

        return null;
    }

    /// Deallocate the linked list's elements, as well as the linked list struct value itself
    pub fn free(self: InorderTraversalEagerIterator) void {
        self.nodes.*.free(self.allocator);
        self.allocator.destroy(self.nodes);
    }
};

const Node = struct {
    value: u8,
    left: ?*Node,
    right: ?*Node,
};

pub const BinarySearchTree = struct {
    allocator: std.mem.Allocator,
    root: ?*Node,

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!BinarySearchTree {
        return BinarySearchTree{ .allocator = allocator, .root = null };
    }

    pub fn insert(self: *BinarySearchTree, value: u8) std.mem.Allocator.Error!void {
        if (self.root == null) {
            const node = try self.allocator.create(Node);
            node.*.value = value;
            node.*.left = null;
            node.*.right = null;
            self.root = node;
            return;
        }

        // If execution has reached here, then the root node cannot be null, hence the
        // unwrapping of the optional `self.root` is safe to do
        try self.insert_recurse(self.root.?, value);
    }

    fn insert_recurse(self: *BinarySearchTree, node: *Node, value: u8) std.mem.Allocator.Error!void {
        const is_value_less_than_current = value < node.*.value;
        if (is_value_less_than_current) {
            if (node.*.left) |left_child| {
                // Carry on recursing down left subtree
                return try self.insert_recurse(left_child, value);
            } else {
                // Value to insert is smaller than value in current node, but the left child is
                // a null node, so set the current node's left child to a new node containing
                // the value to insert.
                const new_node = try self.allocator.create(Node);
                new_node.*.value = value;
                new_node.*.left = null;
                new_node.*.right = null;
                node.*.left = new_node;
                return;
            }
        }

        // If execution has reached here, then the value is >= to the current value.
        //
        // NOTE: Not handling duplicate values for now, so assume value is > current value, so
        // need to recurse down right subtree.
        if (node.*.right) |right_child| {
            return try self.insert_recurse(right_child, value);
        } else {
            // The right child of the current node is null, so set the current node's right
            // child to a new node containing the value to insert.
            const new_node = try self.allocator.create(Node);
            new_node.*.value = value;
            new_node.*.left = null;
            new_node.*.right = null;
            node.*.right = new_node;
            return;
        }
    }

    pub fn remove(self: *BinarySearchTree, value: u8) std.mem.Allocator.Error!void {
        const root_node = if (self.root) |val| val else {
            // TODO: Trying to remove element from empty BST should raise an error
            unreachable;
        };
        const node = if (root_node.*.value == value) root_node else {
            // TODO: Need to recurse down the tree and find the parent of the node to remove.
            // For now, panic if the root node isn't the one to remove.
            unreachable;
        };

        // Value to remove is in the the root node where the root node also has no children
        if (node == root_node and node.*.left == null and node.*.right == null) {
            self.allocator.destroy(node);
            self.root = null;
            return;
        }

        // TODO: Value to remove was in the root node, but the root isn't the only node in the
        // tree, so more needs to be done in this case.
        //
        // If the root node has a left child but no right child, then:
        // - swap the root node with its left child
        // - remove the old root node
        if (node == root_node and node.*.left != null and node.*.right == null) {
            self.root = root_node.*.left;
            self.allocator.destroy(root_node);
            return;
        }

        // TODO: Value to remove is not in the root node. Need to figure out how to remove such
        // values, based on the subtrees of the node it is in.
    }

    pub fn inorderTraversal(self: BinarySearchTree) std.mem.Allocator.Error!InorderTraversalEagerIterator {
        const nodes = try self.getListOfNodePtrs();
        return InorderTraversalEagerIterator{
            .nodes = nodes,
            .allocator = self.allocator,
            .current = 0,
        };
    }

    fn getListOfNodePtrs(self: BinarySearchTree) std.mem.Allocator.Error!*list.SinglyLinkedList(*Node) {
        const index_stack = try self.allocator.create(stack.Stack);
        index_stack.* = stack.Stack.new();
        const visited_nodes = try self.allocator.create(list.SinglyLinkedList(*Node));
        visited_nodes.* = list.SinglyLinkedList(*Node).new();

        // Traverse BST
        try inorder(self.allocator, self.root, index_stack, visited_nodes);

        // Deallocate memory for stack used in traversal
        index_stack.*.free(self.allocator);
        self.allocator.destroy(index_stack);

        return visited_nodes;
    }

    pub fn free(self: *BinarySearchTree) std.mem.Allocator.Error!void {
        const bst_node_ptrs_list = try self.getListOfNodePtrs();

        // `traversal_ptr` is a pointer to a `Node` in a singly linked list, which in turn has
        // a value which is a pointer to a BST `Node`
        //
        // Meaning, to get to a pointer to a BST `Node`, we must:
        // - unwrap the optional pointer to a singly linked list node (to get a pointer to a
        // singly linked list node)
        // - dereference the pointer to a singly linked list node (to get a pointer to a BST
        // node)
        var traversal_ptr = bst_node_ptrs_list.head;
        var count: usize = 0;
        while (traversal_ptr != null) : (count += 1) {
            // `traversal_ptr` has been confirmed to not be null, so the unwrap is safe to do.
            self.allocator.destroy(traversal_ptr.?.*.value);
            traversal_ptr = traversal_ptr.?.next;
        }

        // Deallocate the linked list of BST node pointers
        bst_node_ptrs_list.*.free(self.allocator);
        self.allocator.destroy(bst_node_ptrs_list);
    }
};

test "inorder traversal iterator produces correct ordering of visited nodes" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 };
    const expected_ordering = values;

    // Insert values into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Get eagerly evaluated iterator over BST for performing inorder traversal
    var iterator = try bst.inorderTraversal();

    // Traverse iterator and check each element is as expected, based on the assumption of the
    // array representation of a binary tree's nodes
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(expected_ordering[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "inorder traversal over BST with null nodes produces correct ordering of visited nodes" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 7, 5, 20, 4, 6, 15, 33, 2, 10, 25 };
    const expected_ordering = [_]u8{ 2, 4, 5, 6, 7, 10, 15, 20, 25, 33 };

    // Insert values into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Get inorder traversal iterator over BST
    var iterator = try bst.inorderTraversal();

    // Traverse iterator and check each element is as expected
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(expected_ordering[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "inserting elements into binary search tree produces correct ordering" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 7, 1, 3, 9, 14, 4, 19, 18, 10, 2, 31, 16, 5, 29, 11 };
    const inorder_ordering = [_]u8{ 1, 2, 3, 4, 5, 7, 9, 10, 11, 14, 16, 18, 19, 29, 31 };

    // Insert values into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Get eagerly evaluated iterator over BST for performing inorder traversal
    var iterator = try bst.inorderTraversal();

    // Traverse inorder iterator and check the values are in the expected ordering
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(inorder_ordering[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "empty BST produces inorder iterator of length 0" {
    const allocator = std.testing.allocator;
    const bst = try BinarySearchTree.new(allocator);
    const iterator = try bst.inorderTraversal();
    try std.testing.expectEqual(0, iterator.nodes.len);
    iterator.free();
}

test "remove root node in BST with only one node" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const value = 5;
    try bst.insert(value);
    try bst.remove(value);

    // Get inorder iterator over BST and check its length is zero
    const iterator = try bst.inorderTraversal();
    try std.testing.expectEqual(0, iterator.nodes.len);

    // Free iterator
    iterator.free();
}

test "remove root node in BST with single subtree (left) of root node" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 2, 1 };
    const value_to_remove = 2;
    const value_to_keep = 1;

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Remove root value
    try bst.remove(value_to_remove);

    // Get inorder iterator over BST
    var iterator = try bst.inorderTraversal();

    // Check iterator's length is one
    try std.testing.expectEqual(1, iterator.nodes.len);

    // Check single value in iterator is as expected
    try std.testing.expectEqual(value_to_keep, iterator.next());

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

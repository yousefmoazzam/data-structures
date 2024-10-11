const std = @import("std");

const stack = @import("stack.zig");

/// Perform inorder traversal of binary tree via recursion (assuming an array representation
/// for the binary tree)
fn inorder(allocator: std.mem.Allocator, idx: usize, bst_slice: []?u8, iter_slice: []*u8, index_stack: *stack.Stack, count: *usize) std.mem.Allocator.Error!void {
    if (bst_slice[idx] == null) return;

    // The value being pushed onto the stack has been verified to not be `null`, so the
    // optional can safely be unwrapped
    try index_stack.*.push(allocator, bst_slice[idx].?);
    const left_child_idx: usize = 2 * idx + 1;

    // If the left child of current node is within bounds, keep traversing down the left
    // subtree
    if (left_child_idx < iter_slice.len) {
        try inorder(allocator, left_child_idx, bst_slice, iter_slice, index_stack, count);
    }

    // If execution has reached here, then either the left child wasn't within bounds, or we
    // have returned from a recursive call that occurred in the above `if` statement.
    //
    // In either case, we must now pop off the current value and then note this index/node as
    // the next to be visited.
    if (index_stack.*.pop(allocator)) |_| {} else |_| {
        // If the algorithm is correct, an empty stack should never attempted to be popped.
        // Hence, unreachable.
        unreachable;
    }
    iter_slice[count.*] = &bst_slice[idx].?;
    count.* += 1;

    // Now need to explore right subtree, so check if the right child index is within bounds or
    // not and recurse down it if so
    const right_child_index: usize = 2 * idx + 2;
    if (right_child_index < iter_slice.len) {
        try inorder(allocator, right_child_index, bst_slice, iter_slice, index_stack, count);
    }
}

/// Provides a slice of `u8` pointers in the order of traversal, where the traversal operations
/// have been eagerly evaluated to produce the slice
pub const InorderTraversalEagerIterator = struct {
    slice: []*u8,
    allocator: std.mem.Allocator,
    current: usize,
    len: *usize,

    pub fn next(self: *InorderTraversalEagerIterator) ?u8 {
        if (self.current < self.len.*) {
            const val = self.slice[self.current].*;
            self.current += 1;
            return val;
        }

        return null;
    }

    pub fn free(self: InorderTraversalEagerIterator) void {
        self.allocator.free(self.slice);
        self.allocator.destroy(self.len);
    }
};

pub const BinarySearchTree = struct {
    allocator: std.mem.Allocator,
    slice: []?u8,
    layers: usize,

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!BinarySearchTree {
        return BinarySearchTree{ .slice = try allocator.alloc(?u8, 0), .allocator = allocator, .layers = 0 };
    }

    fn calculateNumberOfElementsInNextLayer(self: BinarySearchTree) usize {
        return self.slice.len + std.math.pow(usize, 2, self.layers);
    }

    fn addLayer(self: *BinarySearchTree) std.mem.Allocator.Error!void {
        const new_slice = try self.allocator.alloc(?u8, self.calculateNumberOfElementsInNextLayer());
        for (0..self.slice.len) |i| {
            new_slice[i] = self.slice[i];
        }

        // Set `null` values for the nodes in the newly added layer
        for (self.slice.len..new_slice.len) |i| {
            new_slice[i] = null;
        }

        self.allocator.free(self.slice);
        self.slice = new_slice;
        self.layers += 1;
    }

    pub fn insert(self: *BinarySearchTree, value: u8) std.mem.Allocator.Error!void {
        if (self.slice.len == 0) {
            const slice = try self.allocator.alloc(?u8, 1);
            slice[0] = value;
            self.allocator.free(self.slice);
            self.slice = slice;
            self.layers += 1;
            return;
        }

        // If execution has reached here, then the BST is non-empty, and now must recurse down
        // the tree until the appropriate place to insert the given value has been found
        try self.insert_recurse(0, value);
    }

    fn insert_recurse(self: *BinarySearchTree, idx: usize, value: u8) std.mem.Allocator.Error!void {
        const current_value = if (self.slice[idx]) |val| val else {
            self.slice[idx] = value;
            return;
        };

        const is_value_less_than_current = value < current_value;
        if (is_value_less_than_current) {
            const left_child_idx: usize = 2 * idx + 1;

            if (left_child_idx < self.slice.len) {
                // Carry on recursing down left subtree
                return try self.insert_recurse(left_child_idx, value);
            }

            // Value is smaller than current value, but the index of the left child of the
            // current node isn't within bounds of the underlying array, so cannot recurse
            // further. Need to add another layer to the BST, and then insert value as the left
            // child of the current node.
            if (left_child_idx >= self.slice.len) {
                try self.addLayer();
            }
            self.slice[left_child_idx] = value;
            return;
        }

        // If execution has reached here, then the value is >= to the current value.
        //
        // NOTE: Not handling duplicate values for now, so assume value is > current value, so
        // need to recurse down right subtree.
        const right_child_idx: usize = 2 * idx + 2;
        if (right_child_idx < self.slice.len) {
            // Carry on recursing down right subtree
            return try self.insert_recurse(right_child_idx, value);
        }

        // If execution has reached here, then the right child index isn;t within bounds, so
        // cannot recurse further. Need to add another layer to the BST, and then insert value
        // as the right child of the current node.
        if (right_child_idx >= self.slice.len) {
            try self.addLayer();
        }
        self.slice[right_child_idx] = value;
        return;
    }

    pub fn inorderTraversal(self: BinarySearchTree) std.mem.Allocator.Error!InorderTraversalEagerIterator {
        const iter_slice = try self.allocator.alloc(*u8, self.slice.len);
        const index_stack = try self.allocator.create(stack.Stack);
        index_stack.* = stack.Stack.new();
        const count = try self.allocator.create(usize);
        count.* = 0;

        // Traverse BST
        try inorder(self.allocator, 0, self.slice, iter_slice, index_stack, count);

        // Deallocate memory for stack used in traversal
        self.allocator.destroy(index_stack);

        return InorderTraversalEagerIterator{
            .slice = iter_slice,
            .allocator = self.allocator,
            .current = 0,
            .len = count,
        };
    }

    pub fn free(self: *BinarySearchTree) void {
        self.allocator.free(self.slice);
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
    bst.free();
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
    bst.free();
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
    bst.free();
}

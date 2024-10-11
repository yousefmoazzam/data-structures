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
    count: usize,

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!BinarySearchTree {
        return BinarySearchTree{ .slice = try allocator.alloc(?u8, 0), .allocator = allocator, .count = 0 };
    }

    pub fn insert(self: *BinarySearchTree, value: ?u8) std.mem.Allocator.Error!void {
        // TODO: Naive insertion implementation, purely to be able to get elements into the
        // slice for the purposes of testing inorder traversal algorithm.
        //
        // Properly implement this later.
        if (self.slice.len == 0) {
            const slice = try self.allocator.alloc(?u8, 15);
            for (slice) |*element| {
                element.* = null;
            }
            self.allocator.free(self.slice);
            self.slice = slice;
        }

        self.slice[self.count] = value;
        self.count += 1;
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
    const expected_ordering = [_]u8{ 7, 3, 8, 1, 9, 4, 10, 0, 11, 5, 12, 2, 13, 6, 14 };

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
    const values = [_]?u8{ 7, 5, 20, 4, 6, 15, 33, 2, null, null, null, 10, null, 25, null };
    const expected_ordering = [_]?u8{ 2, 4, 5, 6, 7, 10, 15, 20, 25, 33 };

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

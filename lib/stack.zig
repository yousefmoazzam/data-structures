const std = @import("std");

const list = @import("linked_list.zig");

pub const Stack = struct {
    pub const Error = error{
        EmptyStack,
    };

    list: list.SinglyLinkedList(u8),

    pub fn new() Stack {
        return Stack{ .list = list.SinglyLinkedList(u8).new() };
    }

    pub fn free(self: *Stack, allocator: std.mem.Allocator) void {
        self.list.free(allocator);
    }

    pub fn size(self: Stack) usize {
        return self.list.len;
    }

    pub fn peek(self: Stack) Error!u8 {
        if (self.size() == 0) {
            return Error.EmptyStack;
        }

        if (self.list.get(0)) |value| {
            return value;
        } else |_| {
            // The only error in the error set that `SinglyLinkedList.get()` can return is
            // `OutOfBounds`. Furthermore, because `peek()` is only ever getting index 0, the
            // only way an error can be returned from calling `SinglyLinkedList.get()` is if
            // the linked list is empty. However, this has already been handled at the start of
            // the method, returning an `EmptyStack` error.
            //
            // Therefore, an error should never be returned at this point, so this else branch
            // should be considered unreachable.
            unreachable;
        }
    }

    pub fn push(self: *Stack, allocator: std.mem.Allocator, value: u8) std.mem.Allocator.Error!void {
        try self.list.prepend(allocator, value);
    }

    pub fn pop(self: *Stack, allocator: std.mem.Allocator) Error!u8 {
        if (self.list.len == 0) {
            return Error.EmptyStack;
        }

        const element = try self.peek();
        if (self.list.delete(allocator, 0)) |_| {
            return element;
        } else |_| {
            // The only error in the error set that `SinglyLinkedList.delete()` can return is
            // `OutOfBounds`. Furthermore, because `Stack.pop()` is only ever calling
            // `SinglyLinkedList.delete()` on index 0, the only way an error can be returned
            // from calling `SinglyLinkedList.delete()` is if the linked list is empty.
            // However, this has already been handled at the start of the method, returning an
            // `EmptyStack` error.
            //
            // Therefore, an error should never be returned at this point, so this else branch
            // should be considered unreachable.
            unreachable;
        }
    }
};

test "create stack" {
    const stack = Stack.new();
    try std.testing.expectEqual(0, stack.size());
}

test "return error if peeking on empty stack" {
    const stack = Stack.new();
    const ret = stack.peek();
    try std.testing.expectError(Stack.Error.EmptyStack, ret);
}

test "push one element onto stack" {
    var stack = Stack.new();
    const allocator = std.testing.allocator;
    const value = 5;
    try stack.push(allocator, value);
    try std.testing.expectEqual(value, try stack.peek());
    stack.free(allocator);
}

test "push multiple elements onto stack" {
    var stack = Stack.new();
    const allocator = std.testing.allocator;
    const values = [_]u8{ 2, 3 };

    // Push values onto stack
    for (values) |value| {
        try stack.push(allocator, value);
    }

    // Check stack is expected size
    try std.testing.expectEqual(values.len, stack.size());

    // Check top of stack is the expected element
    try std.testing.expectEqual(values[values.len - 1], try stack.peek());

    // Free stack
    stack.free(allocator);
}

test "free non-empty stack resets size" {
    var stack = Stack.new();
    const allocator = std.testing.allocator;
    const value = 5;
    try stack.push(allocator, value);
    stack.free(allocator);
    try std.testing.expectEqual(0, stack.size());
}

test "return error if popping empty stack" {
    var stack = Stack.new();
    const allocator = std.testing.allocator;
    const ret = stack.pop(allocator);
    try std.testing.expectError(Stack.Error.EmptyStack, ret);
}

test "pop elements off of multi-element stack" {
    var stack = Stack.new();
    const allocator = std.testing.allocator;
    const values = [_]u8{ 4, 5 };

    // Push element onto stack
    for (values) |value| {
        try stack.push(allocator, value);
    }

    for (0..values.len) |i| {
        // Pop element off the stack and check it's the expected value
        try std.testing.expectEqual(values[values.len - 1 - i], try stack.pop(allocator));

        // Check stack size has reduced by one
        try std.testing.expectEqual(values.len - 1 - i, stack.size());
    }
}

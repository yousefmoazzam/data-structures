const std = @import("std");

const list = @import("linked_list.zig");

const Stack = struct {
    const Error = error{
        EmptyStack,
    };

    list: list.SinglyLinkedList,

    fn new() Stack {
        return Stack{ .list = list.SinglyLinkedList.new() };
    }

    fn free(self: *Stack, allocator: std.mem.Allocator) void {
        self.list.free(allocator);
    }

    fn size(self: Stack) usize {
        return self.list.len;
    }

    fn peek(self: Stack) Error!u8 {
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

    fn push(self: *Stack, allocator: std.mem.Allocator, value: u8) std.mem.Allocator.Error!void {
        try self.list.append(allocator, value);
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

test "push element onto stack" {
    var stack = Stack.new();
    const allocator = std.testing.allocator;
    const value = 5;
    try stack.push(allocator, value);
    try std.testing.expectEqual(value, try stack.peek());
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

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

    fn size(self: Stack) usize {
        return self.list.len;
    }

    fn peek(self: Stack) Error!void {
        if (self.size() == 0) {
            return Error.EmptyStack;
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

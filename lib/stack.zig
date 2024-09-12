const std = @import("std");

const Stack = struct {
    size: usize,

    fn new() Stack {
        return Stack{ .size = 0 };
    }
};

test "create stack" {
    const stack = Stack.new();
    try std.testing.expectEqual(0, stack.size);
}

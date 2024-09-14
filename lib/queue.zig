const std = @import("std");

const Queue = struct {
    size: usize,

    fn new() Queue {
        return Queue{ .size = 0 };
    }
};

test "create queue" {
    const queue = Queue.new();
    try std.testing.expectEqual(0, queue.size);
}

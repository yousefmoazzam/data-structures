const std = @import("std");

const Queue = struct {
    size: usize,

    const Error = error{
        EmptyQueue,
    };

    fn new() Queue {
        return Queue{ .size = 0 };
    }

    fn peek(self: Queue) Error!void {
        if (self.size == 0) {
            return Error.EmptyQueue;
        }
    }
};

test "create queue" {
    const queue = Queue.new();
    try std.testing.expectEqual(0, queue.size);
}

test "return error if peeking on empty queue" {
    const queue = Queue.new();
    const ret = queue.peek();
    try std.testing.expectError(Queue.Error.EmptyQueue, ret);
}

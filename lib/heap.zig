const std = @import("std");

const BinaryHeap = struct {
    const Error = error{
        EmptyHeap,
    };

    size: usize,

    pub fn new() BinaryHeap {
        return BinaryHeap{ .size = 0 };
    }

    pub fn isEmpty(self: BinaryHeap) bool {
        return self.size == 0;
    }

    pub fn peek(self: BinaryHeap) Error!void {
        if (self.isEmpty()) {
            return Error.EmptyHeap;
        }
    }
};

test "create binary heap" {
    const heap = BinaryHeap.new();
    try std.testing.expectEqual(true, heap.isEmpty());
}

test "return error if peeking on empty heap" {
    const heap = BinaryHeap.new();
    const ret = heap.peek();
    try std.testing.expectError(BinaryHeap.Error.EmptyHeap, ret);
}

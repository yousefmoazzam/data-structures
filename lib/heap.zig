const std = @import("std");

const BinaryHeap = struct {
    size: usize,

    pub fn new() BinaryHeap {
        return BinaryHeap{ .size = 0 };
    }

    pub fn isEmpty(self: BinaryHeap) bool {
        return self.size == 0;
    }
};

test "create binary heap" {
    const heap = BinaryHeap.new();
    try std.testing.expectEqual(true, heap.isEmpty());
}

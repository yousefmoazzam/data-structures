const std = @import("std");

const array = @import("array.zig");

const BinaryHeap = struct {
    const Error = error{
        EmptyHeap,
    };

    arr: array.DynamicArray,

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!BinaryHeap {
        return BinaryHeap{ .arr = try array.DynamicArray.new(allocator, 0) };
    }

    pub fn isEmpty(self: BinaryHeap) bool {
        return self.arr.len == 0;
    }

    pub fn peek(self: BinaryHeap) Error!u8 {
        if (self.isEmpty()) {
            return Error.EmptyHeap;
        }

        if (self.arr.get(0)) |value| {
            return value;
        } else |_| {
            // The only error in the error set that `DynamicArray.get()` can return is
            // `OutOfBounds`. Furthermore, because `peek()` is only ever getting index 0, the
            // only way an error can be returned from calling `DynamicArray.get()` is if the
            // dynamic array is empty. However, this has already been handled at the start of
            // the method, returning an `EmptyHeap` error.
            //
            // Therefore, an error should never be returned at this point, so this else branch
            // should be considered unreachable.
            unreachable;
        }
    }

    pub fn enqueue(self: *BinaryHeap, allocator: std.mem.Allocator, value: u8) std.mem.Allocator.Error!void {
        // Add element to the end of the dynamic array
        try self.arr.append(allocator, value);

        // If the heap now has one element (ie, was empty prior to the appending), then that's
        // all that's needed to be done
        if (self.arr.len == 1) {
            return;
        }

        // Execution reaches here if the heap now has two or more elements. Bubble-up the newly
        // added element to its correct position based on its priority (which in turn is based
        // on the value of the `u8`)
        self.bubble_up(value);
    }

    fn bubble_up(self: *BinaryHeap, value: u8) void {
        var hasFinishedBubbling = false;
        var idx = self.arr.len - 1;

        while (!hasFinishedBubbling) {
            // `idx = 0` can't occur here when beginning bubbling-up, since `bubble_up()` is
            // only called when adding an element to an array of length 1 or greater. This
            // means that the length must be at least 2, which means `idx` must be at least 1
            // if starting bubbling-up.
            //
            // `idx = 0` also can't occur as a result of a new iteration of bubbling-up,
            // because if a value has bubbled up all the way to index 0 then it can be
            // bubbled-up no further, and iteration should be terminated before starting
            // bubbling-up again.
            if (idx == 0) unreachable;

            // When `idx = 1`, the defn of the two bindings are simpler:
            // - will be a left child, so `isRightChild = false`
            // - there's only one other value which is the parent, and so the parent index must
            // be 0
            const isRightChild = if (idx == 1) false else (idx % 2 == 0);
            const parentIdx = if (idx == 1) 0 else (if (isRightChild) (idx - 2) / 2 else (idx - 1) / 2);

            // Check if newly added value is less than the value of its parent
            if (self.arr.get(parentIdx)) |parent| {
                if (value < parent) {
                    const tmp = parent;

                    // Swap value with its parent value
                    //
                    // Both `parentIdx and `idx` are guaranteed to be within bounds of the
                    // underlying dynamic array, so the `OutOfBounds` from the `get()` and
                    // `set()` should not occur; hence, unreachable.
                    if (self.arr.set(parentIdx, value)) |_| {} else |_| unreachable;
                    if (self.arr.set(idx, tmp)) |_| {} else |_| unreachable;

                    // Setup bubbling-up for next iteration
                    idx = parentIdx;

                    // However, if the new bubbled-up index of the value is 0, then bubbling-up
                    // has gone as far as it can and needs to be terminated
                    if (idx == 0) hasFinishedBubbling = true;
                } else hasFinishedBubbling = true;
            } else |_| {
                // `parentIdx` must be within the bounds of the dynamic array, because the
                // parent index must be smaller than the index of the newly added element, and
                // the index of the newly added is within bounds -> an index larger than the
                // parent index is in bounds, so the parent index must also be in bounds.
                // Therefore, the `OutOfBounds` error from `DynamicArray.get()` should not
                // occur here, hence, unreachable.
                unreachable;
            }
        }
    }
};

test "create binary heap" {
    const allocator = std.testing.allocator;
    const heap = try BinaryHeap.new(allocator);
    try std.testing.expectEqual(true, heap.isEmpty());
}

test "return error if peeking on empty heap" {
    const allocator = std.testing.allocator;
    const heap = try BinaryHeap.new(allocator);
    const ret = heap.peek();
    try std.testing.expectError(BinaryHeap.Error.EmptyHeap, ret);
}

test "enqueue elements onto binary heap" {
    const allocator = std.testing.allocator;
    var heap = try BinaryHeap.new(allocator);
    const values = [_]u8{ 6, 3, 7, 2, 9, 8, 1 };
    const expectedHighestPriority = [_]u8{ 6, 3, 3, 2, 2, 2, 1 };

    // Sanity check that the test is correct: make sure `values` and `expectedHighestPriority`
    // are the same length
    try std.testing.expectEqual(values.len, expectedHighestPriority.len);

    // Enqueue elements, and check that the top priority element changes when expected
    for (0..values.len) |i| {
        try heap.enqueue(allocator, values[i]);
        try std.testing.expectEqual(expectedHighestPriority[i], try heap.peek());
    }
}

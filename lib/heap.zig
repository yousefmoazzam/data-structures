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

    pub fn free(self: *BinaryHeap, allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        try self.arr.free(allocator);
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
        self.bubble_up(value, self.arr.len - 1);
    }

    fn bubble_up(self: *BinaryHeap, value: u8, index: usize) void {
        var hasFinishedBubbling = false;
        var idx = index;

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

    pub fn dequeue(self: *BinaryHeap) Error!u8 {
        if (self.isEmpty()) {
            return Error.EmptyHeap;
        }

        if (self.arr.len == 1) {
            if (self.arr.get(0)) |value| {
                // If execution has reached here, then `self.arr.len = 1`, so deleting the 0th
                // index element using `DynamicArray.delete(0)` should never return an
                // `OutOfBounds` error. Hence, unreachable.
                if (self.arr.delete(0)) |_| {} else |_| unreachable;
                return value;
            } else |_| {
                // If execution has reached here, then `self.arr.len = 1`, so getting the 0th
                // index element using `DynamicArray.get(0)` should never return an
                // `OutOfBounds` error. Hence, unreachable.
                unreachable;
            }
        }

        // If execution has reached here, then `self.arr.len > 1`, so getting the 0th index
        // element using `DynamicArray.get(0)` should never return an `OutOfBounds` error.
        // Hence, unreachable.
        const value_to_dequeue = if (self.arr.get(0)) |val| val else |_| unreachable;
        // `self.arr.len - 1` should be a valid index in any array with length > 1, so
        // `DynamicArray.get(self.arr.len - 1)` should never return an `OutOfBounds` error.
        // Hence, unreachable.
        const value_to_swap = if (self.arr.get(self.arr.len - 1)) |val| val else |_| unreachable;

        // Replace root value with end value (no need to replace end value with value to
        // dequeue, because it's going to be removed anyway, and we already have its value
        // stored in `value_to_dequeue`)
        //
        // The reasoning for the use of unreachable is the same as for both cases above
        // regarding `DynamicArray.get()`, but now for  `DynamicArray.set()`
        if (self.arr.set(0, value_to_swap)) |_| {} else |_| unreachable;

        // Remove end value
        if (self.arr.delete(self.arr.len - 1)) |_| {} else |_| unreachable;

        // Bubble-down new root value
        self.bubble_down(value_to_swap, 0);

        // Return the value that was removed
        return value_to_dequeue;
    }

    fn bubble_down(self: *BinaryHeap, newRoot: u8, index: usize) void {
        var hasFinishedBubbling = false;
        var idx: usize = index;

        while (!hasFinishedBubbling) {
            const leftChildIdx = 2 * idx + 1;
            const rightChildIdx = 2 * idx + 2;

            // If the left child index is past the end of the array, then so will the right
            // child index too. In this case, bubbling-down has completed and iteration should
            // terminate.
            if (leftChildIdx > self.arr.len - 1) {
                hasFinishedBubbling = true;
                continue;
            }

            // If execution has gotten this far, then the left child must be within the bounds
            // of the array.
            if (rightChildIdx > self.arr.len - 1) {
                // If only the right child index is past the end of the array but the left
                // child is within the array, then only the left child exists and thus must be
                // the one to compare with in the bubbling-down process.
                const childValue = if (self.arr.get(leftChildIdx)) |value| value else |_| unreachable;
                if (newRoot > childValue) {
                    // Swap value and child value
                    //
                    // If the left child index is within the bounds of the array, then so must
                    // the parent of it. This means that an `OutOfBounds` error for the use of
                    // `DynamicArray.set`()` isn't possible. Hence, unreachable.
                    if (self.arr.set(idx, childValue)) |_| {} else |_| unreachable;
                    if (self.arr.set(leftChildIdx, newRoot)) |_| {} else |_| unreachable;
                }

                // Because there was only one child element in the swap above, bubbling-down
                // has gone as far as it can, so terminate the process.
                hasFinishedBubbling = true;
            } else {
                // If execution has gotten to this branch, then both the left and right
                // children exist.

                // Both children exist, so `DynamicArray.get()` should not return an
                // `OutOfBounds` error. Hence, unreachable.
                const leftChildValue = if (self.arr.get(leftChildIdx)) |val| val else |_| unreachable;
                const rightChildValue = if (self.arr.get(rightChildIdx)) |val| val else |_| unreachable;

                // Find which child element is smaller
                const smallerChildIdx = if (leftChildValue < rightChildValue) leftChildIdx else rightChildIdx;
                const smallerChildValue = if (smallerChildIdx == leftChildIdx) leftChildValue else rightChildValue;
                if (newRoot > smallerChildValue) {
                    // Swap value and child value
                    //
                    // Both the smaller child index and the index of the bubbled-down value
                    // must be within the bounds of the array, so `OutOfBounds` shouldn't be
                    // returned by `DynamicArray.set()` in either case. Hence, unreachable.
                    if (self.arr.set(idx, smallerChildValue)) |_| {} else |_| unreachable;
                    if (self.arr.set(smallerChildIdx, newRoot)) |_| {} else |_| unreachable;
                }

                // Carry onto the next iteration to check the new children indices and see if
                // bubbling-down should carry on or not.
                idx = smallerChildIdx;
            }
        }
    }

    pub fn remove(self: BinaryHeap) Error!void {
        if (self.isEmpty()) {
            return Error.EmptyHeap;
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

    // Free heap
    try heap.free(allocator);
}

test "freeing heap resets heap to empty" {
    const allocator = std.testing.allocator;
    var heap = try BinaryHeap.new(allocator);
    const values = [_]u8{ 1, 2, 3 };

    // Enqueue elements
    for (values) |value| {
        try heap.enqueue(allocator, value);
    }

    // Free heap
    try heap.free(allocator);

    // Check that the heap is empty
    try std.testing.expectEqual(true, heap.isEmpty());
}

test "return empty error if dequeueing from empty heap" {
    const allocator = std.testing.allocator;
    var heap = try BinaryHeap.new(allocator);
    const ret = heap.dequeue();
    try std.testing.expectError(BinaryHeap.Error.EmptyHeap, ret);
}

test "dequeue only element from single element heap" {
    const allocator = std.testing.allocator;
    var heap = try BinaryHeap.new(allocator);
    const value = 6;

    // Enqueue element
    try heap.enqueue(allocator, value);

    // Dequeue element, and verify the value is the one expected, and also that the heap is now
    // empty
    try std.testing.expectEqual(value, try heap.dequeue());
    try std.testing.expectEqual(true, heap.isEmpty());

    // Free heap
    try heap.free(allocator);
}

test "dequeue multiple elements from binary heap" {
    const allocator = std.testing.allocator;
    var heap = try BinaryHeap.new(allocator);
    const values = [_]u8{ 6, 3, 7, 2, 9, 8, 1 };
    const expectedPriorityOrdering = [_]u8{ 1, 2, 3, 6, 7, 8, 9 };

    // Sanity check that the test is correct: make sure `values` and `expectedHighestPriority`
    // are the same length
    try std.testing.expectEqual(values.len, expectedPriorityOrdering.len);

    // Enqueue elements onto heap
    for (values) |value| {
        try heap.enqueue(allocator, value);
    }

    // Dequeue all elements, and check the ordering of elements follows the expected priority
    for (0..values.len) |i| {
        try std.testing.expectEqual(expectedPriorityOrdering[i], try heap.dequeue());
    }

    // Free heap
    try heap.free(allocator);
}

test "return error if removing element from empty heap" {
    const allocator = std.testing.allocator;
    const heap = try BinaryHeap.new(allocator);
    const ret = heap.remove();
    try std.testing.expectError(BinaryHeap.Error.EmptyHeap, ret);
}

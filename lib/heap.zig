const std = @import("std");

const array = @import("array.zig");

const BinaryHeap = struct {
    const Error = error{
        EmptyHeap,
        ElementNotFound,
    };

    arr: array.DynamicArray(u8),

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!BinaryHeap {
        return BinaryHeap{ .arr = try array.DynamicArray(u8).new(allocator, 0) };
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

    /// Get the index of the parent element. Assumes that `idx` is not zero.
    fn get_parent_index(idx: usize) usize {
        // When `idx = 1`, the defn of the two bindings are simpler:
        // - will be a left child, so `isRightChild = false`
        // - there's only one other value which is the parent, and so the parent index must be
        // 0
        const isRightChild = if (idx == 1) false else (idx % 2 == 0);
        const parentIdx = if (idx == 1) 0 else (if (isRightChild) (idx - 2) / 2 else (idx - 1) / 2);
        return parentIdx;
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

            const parentIdx = get_parent_index(idx);

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

    fn bubble_down(self: *BinaryHeap, value: u8, index: usize) void {
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
                const childValue = if (self.arr.get(leftChildIdx)) |val| val else |_| unreachable;
                if (value > childValue) {
                    // Swap value and child value
                    //
                    // If the left child index is within the bounds of the array, then so must
                    // the parent of it. This means that an `OutOfBounds` error for the use of
                    // `DynamicArray.set`()` isn't possible. Hence, unreachable.
                    if (self.arr.set(idx, childValue)) |_| {} else |_| unreachable;
                    if (self.arr.set(leftChildIdx, value)) |_| {} else |_| unreachable;
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
                if (value > smallerChildValue) {
                    // Swap value and child value
                    //
                    // Both the smaller child index and the index of the bubbled-down value
                    // must be within the bounds of the array, so `OutOfBounds` shouldn't be
                    // returned by `DynamicArray.set()` in either case. Hence, unreachable.
                    if (self.arr.set(idx, smallerChildValue)) |_| {} else |_| unreachable;
                    if (self.arr.set(smallerChildIdx, value)) |_| {} else |_| unreachable;
                }

                // Carry onto the next iteration to check the new children indices and see if
                // bubbling-down should carry on or not.
                idx = smallerChildIdx;
            }
        }
    }

    pub fn remove(self: *BinaryHeap, value: u8) Error!void {
        if (self.isEmpty()) {
            return Error.EmptyHeap;
        }

        // Check if element to remove is the root, in which case we can dequeue instead
        if (self.peek()) |root| {
            if (root == value) {
                // An empty heap has already been handled at the start of the method, so
                // dequeueing can't return `EmptyHeap`. Hence, unreachable.
                if (self.dequeue()) |_| {} else |_| unreachable;
                return;
            }
        } else |_| {
            // The underlying dynamic array has already been determined to not be zero-length,
            // so index 0 is within bounds. This means peeking can't return `EmptyHeap`, hence,
            // unreachable.
            unreachable;
        }

        // If execution has reached here, then the element to remove is not the root.
        var idx: usize = 0;

        // The underlying dynamic array has already been determined to not be zero-length, so
        // index 0 is within bounds. Also, the end index `self.arr.len` is always within
        // bounds due to `get_slice()` replicating the exclusion of the last element (like zig
        // ranges do). Therefore, there's no way for this use of `DynamicArray.get_slice()` to
        // return `OutOfBounds`. Hence, unreachable.
        const fullArrSlice = if (self.arr.get_slice(0, self.arr.len)) |slc| slc else |_| unreachable;
        for (fullArrSlice[1..], 1..) |elem, i| {
            if (elem == value) {
                // Store index of value for later, after the element has been been removed and
                // when it needs to be decided if bubbling-up/down must be done
                idx = i;

                // Replace value to remove with value at end of the underlying dynamic array
                const endValue = fullArrSlice[fullArrSlice.len - 1];
                fullArrSlice[i] = endValue;

                // Remove value
                //
                // The index "array length - 1" should always be within bounds, so
                // `DynamicArray.delete(self.arr.len - 1)` should never return an `OutOfBounds`
                // error. Hence, unreachable.
                if (self.arr.delete(self.arr.len - 1)) |_| {} else |_| unreachable;
                break;
            }
        }

        // Check if `idx` is still 0. If it is, then the given element to remove hasn't been
        // found in the heap, so return an "element not found" error
        if (idx == 0) return Error.ElementNotFound;

        // If `idx` is non-zero, then the value was found in the heap. Check if value that is
        // now where the value to remove was originally needs to be bubbled-down or up

        // Check parent element. Because we have already dealt with the case of the element to
        // remove being the root, we can assume here that the element is not the root and thus
        // must have a parent element.
        //
        // Get parent index
        const parentIdx = get_parent_index(idx);
        // If `idx` is within bounds, then the parent index should be. So, `DynamicArray.get()`
        // shouldn't return an `OutOfBounds` error here. Hence, unreachable.
        const parentValue = if (self.arr.get(parentIdx)) |val| val else |_| unreachable;

        // Compare value of parent with value that has been put in place of the value that was
        // removed
        //
        // If value is smaller than parent, then bubble-up and return
        if (value < parentValue) {
            self.bubble_up(value, idx);
            return;
        }

        // If execution has reached here, then the value couldn't be bubbled-up. So, now check
        // if the value can be bubbled-down.

        // Check if there are any children (if not, can't bubble-down)
        const leftChildIdx = idx * 2 + 1;
        const rightChildIdx = idx * 2 + 2;
        if (leftChildIdx < self.arr.len) {
            // Left child exists so can potentially can bubble-down. Compare value with left
            // child to see if value is greater than left child or not
            //
            // The left child index has already been confirmed to be within bounds of the
            // dynamic array, so `DynamicArray.get()` shouldn't return an `OutOfBounds` error
            // here. Hence, unreachable.
            const leftChildValue = if (self.arr.get(leftChildIdx)) |val| val else |_| unreachable;
            if (value > leftChildValue) {
                self.bubble_down(value, idx);
                return;
            }

            // If execution has gotten here, then the value was not larger than the left child.
            //
            // Now need to check if right child index is within bounds or not
            if (rightChildIdx < self.arr.len) {
                // If right child is within bounds, then compare value with right child now
                //
                // The right child index has already been confirmed to be within bounds of the
                // dynamic array, so `DynamicArray.get()` shouldn't return an `OutOfBounds`
                // error here. Hence, unreachable.
                const rightChildValue = if (self.arr.get(rightChildIdx)) |val| val else |_| unreachable;
                if (value > rightChildValue) {
                    self.bubble_down(value, idx);
                    return;
                }
            }
            // If right child index is not within bounds, then there are no child nodes and we
            // can't bubble-down. Getting this far means that the element's position already
            // satisfies the heap invariant and that there's nothing else that needs to be
            // done.
            return;
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
    var heap = try BinaryHeap.new(allocator);
    const ret = heap.remove(3);
    try std.testing.expectError(BinaryHeap.Error.EmptyHeap, ret);
}

test "return error if removing element that isn't in heap" {
    const allocator = std.testing.allocator;
    var heap = try BinaryHeap.new(allocator);
    const values = [_]u8{ 4, 8, 2, 3, 3, 9 };
    const nonExistentElementToRemove = 5;

    // Enqueue elements
    for (values) |value| {
        try heap.enqueue(allocator, value);
    }

    // Attempt to remove non-existent element in heap
    const ret = heap.remove(nonExistentElementToRemove);

    // Check that an "element not found" error is returned
    try std.testing.expectError(BinaryHeap.Error.ElementNotFound, ret);

    // Free heap
    try heap.free(allocator);
}

test "remove element that happens to be root element of heap" {
    const allocator = std.testing.allocator;
    var heap = try BinaryHeap.new(allocator);
    const values = [_]u8{ 6, 3, 12, 5, 1, 7 };

    // Enqueue values
    for (values) |value| {
        try heap.enqueue(allocator, value);
    }

    // Remove root element 1, and peek to check that the new root is the expected value 3
    try heap.remove(1);
    try std.testing.expectEqual(3, try heap.peek());

    // Free heap
    try heap.free(allocator);
}

test "remove element that exists in heap from heap" {
    const allocator = std.testing.allocator;
    var heap = try BinaryHeap.new(allocator);
    const values = [_]u8{ 6, 3, 12, 5, 1, 7 };
    const elementsToRemove = [_]u8{ 6, 12, 1 };
    const orderedElementsToDequeue = [_]u8{ 3, 5, 7 };

    // Enqueue values
    for (values) |value| {
        try heap.enqueue(allocator, value);
    }

    // Remove half the elements from heap
    for (elementsToRemove) |value| {
        try heap.remove(value);
    }

    // Dequeue the other half of elements, and check that the order is as expected
    for (orderedElementsToDequeue) |value| {
        try std.testing.expectEqual(value, try heap.dequeue());
    }

    // Free heap
    try heap.free(allocator);
}

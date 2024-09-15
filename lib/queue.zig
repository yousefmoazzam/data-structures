const std = @import("std");

const linked_list = @import("linked_list.zig");

const Queue = struct {
    list: linked_list.SinglyLinkedList,

    const Error = error{
        EmptyQueue,
        ElementNotFound,
    };

    fn new() Queue {
        return Queue{ .list = linked_list.SinglyLinkedList.new() };
    }

    fn free(self: *Queue, allocator: std.mem.Allocator) void {
        self.list.free(allocator);
    }

    fn peek(self: Queue) Error!u8 {
        if (self.list.len == 0) {
            return Error.EmptyQueue;
        }

        if (self.list.get(0)) |value| {
            return value;
        } else |_| {
            // The only error in the error set that `SinglyLinkedList.get()` can return is
            // `OutOfBounds`. Furthermore, because `peek()` is only ever getting index 0, the
            // only way an error can be returned from calling `SinglyLinkedList.get()` is if
            // the linked list is empty. However, this has already been handled at the start of
            // the method, returning an `EmptyQueue` error.
            //
            // Therefore, an error should never be returned at this point, so this else branch
            // should be considered unreachable.
            unreachable;
        }
    }

    fn search(self: Queue, value: u8) Error!usize {
        if (self.size() == 0) {
            return Error.EmptyQueue;
        }

        // Check front of queue
        if (self.list.get(0)) |head| {
            if (head == value) {
                return 0;
            }
        } else |_| {
            // The only error in the error set that `SinglyLinkedList.get()` can return is
            // `OutOfBounds`. Furthermore, because the use of `get()` here is only ever getting
            // index 0, the only way an error can be returned from calling
            // `SinglyLinkedList.get()` is if the linked list is empty. However, this has
            // already been handled at the start of the method, returning an `EmptyQueue`
            // error.
            //
            // Therefore, an error should never be returned at this point, so this else branch
            // should be considered unreachable.
            unreachable;
        }

        // Check back of queue
        if (self.list.get(self.list.len - 1)) |head| {
            if (head == value) {
                return self.list.len - 1;
            }
        } else |_| {
            // The only error in the error set that `SinglyLinkedList.get()` can return is
            // `OutOfBounds`. Furthermore, because the use of `get()` here is only ever getting
            // the index equal to the length of the list minus 1 (which is always a valid index
            // in the list, it's the last index), the `OutOfBounds` error will never occur.
            //
            // Therefore, an error should never be returned at this point, so this else branch
            // should be considered unreachable.
            unreachable;
        }

        // Iterate through elements in the queue and check if the given value appears
        // anywhere
        var traversalPtr = self.list.head;
        var count: usize = 0;
        while (count < self.list.len - 1) : (count += 1) {
            if (traversalPtr.?.value == value) {
                // TODO: Return index
                return 0;
            }
            traversalPtr = traversalPtr.?.next;
        }
        // The entire queue has been traversed and the element hasn't been found, so return an
        // error indicating that the given element isn't in the queue
        return Error.ElementNotFound;
    }

    fn size(self: Queue) usize {
        return self.list.len;
    }

    fn enqueue(self: *Queue, allocator: std.mem.Allocator, value: u8) std.mem.Allocator.Error!void {
        try self.list.append(allocator, value);
    }
};

test "create queue" {
    const queue = Queue.new();
    try std.testing.expectEqual(0, queue.size());
}

test "return error if peeking on empty queue" {
    const queue = Queue.new();
    const ret = queue.peek();
    try std.testing.expectError(Queue.Error.EmptyQueue, ret);
}

test "enqueue one element to queue" {
    var queue = Queue.new();
    const allocator = std.testing.allocator;
    const value = 3;
    try queue.enqueue(allocator, value);
    try std.testing.expectEqual(1, queue.size());
    try std.testing.expectEqual(value, try queue.peek());
    queue.free(allocator);
}

test "free non-empty queue resets size" {
    var queue = Queue.new();
    const allocator = std.testing.allocator;
    const value = 4;

    // Enqueue element first
    try queue.enqueue(allocator, value);

    // Free the queue
    queue.free(allocator);

    // Check that the queue size has reset to 0
    try std.testing.expectEqual(0, queue.size());
}

test "return error for search in empty queue" {
    const queue = Queue.new();
    const ret = queue.search(3);
    try std.testing.expectError(Queue.Error.EmptyQueue, ret);
}

test "return error for search of non-existent element in non-empty queue" {
    var queue = Queue.new();
    const allocator = std.testing.allocator;
    const valueInQueue = 5;
    const valueNotInQueue = 6;

    // Enqueue element onto queue
    try queue.enqueue(allocator, valueInQueue);

    // Search for element that isn't in the queue
    const ret = queue.search(valueNotInQueue);
    try std.testing.expectError(Queue.Error.ElementNotFound, ret);

    // Free queue
    queue.free(allocator);
}

test "search for element that is at front of queue" {
    var queue = Queue.new();
    const allocator = std.testing.allocator;
    const values = [_]u8{ 2, 3 };

    // Enqueue elements
    for (values) |value| {
        try queue.enqueue(allocator, value);
    }

    // Search for element that should be at the front of the queue
    try std.testing.expectEqual(0, queue.search(values[0]));

    // Free queue
    queue.free(allocator);
}

test "search for element that is at back of queue" {
    var queue = Queue.new();
    const allocator = std.testing.allocator;
    const values = [_]u8{ 4, 5 };

    // Enqueue elements
    for (values) |value| {
        try queue.enqueue(allocator, value);
    }

    // Search for element that should be at the back of the queue;
    try std.testing.expectEqual(values.len - 1, queue.search(values[values.len - 1]));

    // Free queue
    queue.free(allocator);
}

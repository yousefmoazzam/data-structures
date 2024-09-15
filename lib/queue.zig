const std = @import("std");

const linked_list = @import("linked_list.zig");

const Queue = struct {
    list: linked_list.SinglyLinkedList,

    const Error = error{
        EmptyQueue,
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

    fn search(self: Queue) Error!void {
        if (self.size() == 0) {
            return Error.EmptyQueue;
        }
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
    const ret = queue.search();
    try std.testing.expectError(Queue.Error.EmptyQueue, ret);
}

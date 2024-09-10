const std = @import("std");

const SinglyLinkedList = struct {
    const Node = struct {
        value: u8,
        next: ?*Node,
    };

    const Error = error{
        OutOfBounds,
    };

    len: usize,
    head: ?*Node,
    tail: ?*Node,

    fn new() SinglyLinkedList {
        return SinglyLinkedList{
            .len = 0,
            .head = null,
            .tail = null,
        };
    }

    fn free(self: *SinglyLinkedList, allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        // Zero elements in the linked list
        if (self.len == 0) {
            return;
        }

        // One or more elements in the linked list
        var next = self.head.?.next;
        while (next != null) {
            allocator.destroy(self.head.?);
            self.head = next;
            next = self.head.?.next;
        }
        allocator.destroy(self.head.?);
        self.len = 0;
    }

    fn get(self: SinglyLinkedList, idx: usize) Error!u8 {
        if (idx >= self.len) {
            return Error.OutOfBounds;
        }

        var node = self.head;
        var i: usize = 0;
        while (i < idx) : (i += 1) {
            node = node.?.next;
        }
        return node.?.value;
    }

    fn append(self: *SinglyLinkedList, allocator: std.mem.Allocator, value: u8) std.mem.Allocator.Error!void {
        var node = try allocator.create(Node);
        node.value = value;
        node.next = null;

        if (self.len == 0) {
            self.head = node;
        } else {
            self.tail.?.next = node;
        }

        self.tail = node;
        self.len += 1;
    }

    fn prepend(self: *SinglyLinkedList, allocator: std.mem.Allocator, value: u8) std.mem.Allocator.Error!void {
        var node = try allocator.create(Node);
        node.value = value;
        node.next = self.head;
        self.head = node;
        self.len += 1;
    }

    fn insert(self: *SinglyLinkedList, allocator: std.mem.Allocator, idx: usize, value: u8) (std.mem.Allocator.Error || Error)!void {
        if (idx > self.len) {
            return Error.OutOfBounds;
        }

        if (idx == self.len) {
            return self.append(allocator, value);
        }

        var node = try allocator.create(Node);
        node.value = value;

        // Traverse list until the index before the index to insert new value at
        var traversalPtr = self.head;
        var count: usize = 0;
        while (count < idx - 1) : (count += 1) {
            // If execution gets past the first two `if` conditions earlier in the method, all
            // nodes traversed in this while loop should not be null, so `.?` is safe to do
            // here and won't ever cause a panic I think
            traversalPtr = traversalPtr.?.next;
        }
        // Make the `next` field of the new node point to the node that is currently at `idx`
        node.next = traversalPtr.?.next;
        // Modify the `next` field of the node at `idx - 1` to point to the new node
        traversalPtr.?.next = node;
    }
};

test "create singly linked list" {
    const list = SinglyLinkedList.new();
    try std.testing.expectEqual(0, list.len);
}

test "append elements to singly linked list" {
    var list = SinglyLinkedList.new();
    const valuesToAppend = [_]u8{ 4, 5, 6 };
    const allocator = std.testing.allocator;

    // Append values to list
    for (valuesToAppend) |value| {
        try list.append(allocator, value);
    }

    // Verify that the list is the expected length
    try std.testing.expectEqual(valuesToAppend.len, list.len);

    // Verify that the list contains the expected elements
    for (0..valuesToAppend.len) |i| {
        try std.testing.expectEqual(valuesToAppend[i], list.get(i));
    }

    // Free linked list
    try list.free(allocator);
}

test "free multi-element singly linked list" {
    var list = SinglyLinkedList.new();
    const valuesToAppend = [_]u8{ 1, 2 };
    const allocator = std.testing.allocator;

    // Append values to list
    for (valuesToAppend) |value| {
        try list.append(allocator, value);
    }

    // Free linked list and check that it is empty
    try list.free(allocator);
    try std.testing.expectEqual(0, list.len);
}

test "return out of bounds error get index" {
    const list = SinglyLinkedList.new();
    const ret = list.get(0);
    try std.testing.expectError(SinglyLinkedList.Error.OutOfBounds, ret);
}

test "prepend elements to singly linked list" {
    var list = SinglyLinkedList.new();
    const valuesToPrepend = [_]u8{ 6, 7, 8 };
    const allocator = std.testing.allocator;

    // Prepend values to list
    for (valuesToPrepend) |value| {
        try list.prepend(allocator, value);
    }

    // Verify that the list contains the expected elements at the expected indices
    for (0..valuesToPrepend.len) |i| {
        try std.testing.expectEqual(valuesToPrepend[valuesToPrepend.len - 1 - i], try list.get(i));
    }

    // Free linked list
    try list.free(allocator);
}

test "return out of bound error insert index" {
    var list = SinglyLinkedList.new();
    const allocator = std.testing.allocator;
    const ret = list.insert(allocator, 1, 5);
    try std.testing.expectError(SinglyLinkedList.Error.OutOfBounds, ret);
}

test "insert element at index equal to length of singly linked list" {
    var list = SinglyLinkedList.new();
    const value = 5;
    const allocator = std.testing.allocator;
    try list.insert(allocator, 0, value);
    try std.testing.expectEqual(value, try list.get(0));
    try list.free(allocator);
}

test "insert element at index in middle of singly linked list" {
    var list = SinglyLinkedList.new();
    const valuesToAdd = [_]u8{ 3, 4, 5, 6 };
    const middleIndex = 2;
    const allocator = std.testing.allocator;

    // Append first three values to list
    for (0..valuesToAdd.len) |i| {
        try list.append(allocator, valuesToAdd[i]);
    }

    // Insert last value at middle index
    try list.insert(allocator, middleIndex, valuesToAdd[3]);

    // Check that inserted value is at expected middle index
    try std.testing.expectEqual(valuesToAdd[3], try list.get(middleIndex));

    // Free list
    try list.free(allocator);
}

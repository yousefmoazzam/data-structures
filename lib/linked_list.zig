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

    fn free(self: *SinglyLinkedList, allocator: std.mem.Allocator) void {
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

    fn delete(self: *SinglyLinkedList, allocator: std.mem.Allocator, idx: usize) Error!void {
        if (idx >= self.len) {
            return Error.OutOfBounds;
        }

        if (idx == 0) {
            const newHead = self.head.?.next;
            allocator.destroy(self.head.?);
            self.head = newHead;
            self.len -= 1;
            return;
        }

        // Get pointer to node before the node to delete
        var traversalPtr = self.head;
        var count: usize = 0;
        while (count < idx - 1) : (count += 1) {
            traversalPtr = traversalPtr.?.next;
        }

        if (idx == self.len - 1) {
            // The node before the one to delete in this case is the penultimate node. Because
            // it's the penultimate node, it'll be the last node after deletion, so set its
            // `next` field to null
            traversalPtr.?.next = null;
            // Deallocate old last node using the tail
            allocator.destroy(self.tail.?);
            // Reassign the tail to be the new last node
            self.tail = traversalPtr;
            // Decrement length by one
            self.len -= 1;
            return;
        }

        // If execution has reached this point, the node to delete must be at an index in the
        // middle of the list
        //
        // Modify the `next` field of the node at `idx - 1` to refer to the node at `idx + 1`
        const nodeToRemovePtr = traversalPtr.?.next;
        traversalPtr.?.next = nodeToRemovePtr.?.next;
        // Delete node at `idx`
        allocator.destroy(nodeToRemovePtr.?);
        self.len -= 1;
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
    list.free(allocator);
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
    list.free(allocator);
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
    list.free(allocator);
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
    list.free(allocator);
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
    list.free(allocator);
}

test "return out of bounds error delete index" {
    var list = SinglyLinkedList.new();
    const allocator = std.testing.allocator;
    const ret = list.delete(allocator, 0);
    try std.testing.expectError(SinglyLinkedList.Error.OutOfBounds, ret);
}

test "delete 0th element in non-empty singly linked list" {
    var list = SinglyLinkedList.new();
    const allocator = std.testing.allocator;
    const listValues = [_]u8{ 2, 3 };

    // Add elements to list first
    for (listValues) |value| {
        try list.append(allocator, value);
    }

    // Delete 0th element
    try list.delete(allocator, 0);

    // Check that the list length has decreased by one
    try std.testing.expectEqual(listValues.len - 1, list.len);

    // Check that the list contains the expected value
    try std.testing.expectEqual(listValues[1], try list.get(0));

    // Free list
    list.free(allocator);
}

test "delete last element in singly linked list" {
    var list = SinglyLinkedList.new();
    const allocator = std.testing.allocator;
    const values = [_]u8{ 1, 2, 3 };

    // Add elements to list first
    for (values) |value| {
        try list.append(allocator, value);
    }

    // Delete last element
    try list.delete(allocator, values.len - 1);

    // Check that the list length has decreased by one
    try std.testing.expectEqual(values.len - 1, list.len);

    // Check that the list contains the expected values
    for (0..values.len - 1) |i| {
        try std.testing.expectEqual(values[i], try list.get(i));
    }

    // Free list
    list.free(allocator);
}

test "delete middle index in non-empty linked list" {
    var list = SinglyLinkedList.new();
    const allocator = std.testing.allocator;
    const listValues = [_]u8{ 4, 5, 6 };

    // Add elements to list first
    for (listValues) |value| {
        try list.append(allocator, value);
    }

    // Delete middle index
    try list.delete(allocator, 1);

    // Check that the list length has decreased by one
    try std.testing.expectEqual(listValues.len - 1, list.len);

    // Check that the list contains the expected values
    try std.testing.expectEqual(listValues[0], try list.get(0));
    try std.testing.expectEqual(listValues[2], try list.get(1));

    // Free list
    list.free(allocator);
}

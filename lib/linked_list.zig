const std = @import("std");

const SinglyLinkedList = struct {
    const Node = struct {
        value: u8,
        next: ?*Node,
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

    fn get(self: SinglyLinkedList, idx: usize) u8 {
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
}

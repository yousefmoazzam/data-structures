const std = @import("std");

const SinglyLinkedList = struct {
    len: usize,

    fn new() SinglyLinkedList {
        return SinglyLinkedList{ .len = 0 };
    }
};

test "create singly linked list" {
    const list = SinglyLinkedList.new();
    try std.testing.expectEqual(0, list.len);
}

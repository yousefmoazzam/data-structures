const std = @import("std");

const array = @import("array.zig");
const hash_table = @import("hash_table.zig");

const Node = struct {
    value: u8,
    parent: *Node,
};

pub const UnionFind = struct {
    /// Number of elements in the data structure
    count: usize,
    /// Underlying data structure to hold elements
    arr: *array.DynamicArray(Node),
    allocator: std.mem.Allocator,
    map: *hash_table.HashTable(usize),

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!UnionFind {
        const arr = try allocator.create(array.DynamicArray(Node));
        arr.* = try array.DynamicArray(Node).new(allocator, 0);
        const map = try allocator.create(hash_table.HashTable(usize));
        map.* = try hash_table.HashTable(usize).new(allocator);
        return UnionFind{
            .arr = arr,
            .count = 0,
            .allocator = allocator,
            .map = map,
        };
    }

    pub fn free(self: *UnionFind) std.mem.Allocator.Error!void {
        try self.arr.*.free(self.allocator);
        self.allocator.destroy(self.arr);
        try self.map.*.free(self.allocator);
        self.allocator.destroy(self.map);
    }

    pub fn insert(self: *UnionFind, value: u8) std.mem.Allocator.Error!void {
        // Create node containing the value, but don't set the parent field yet. This is
        // because it's a pointer, and appending the node to the dynamic array will cause a
        // copy of the stack-allocated node instance to be put into the dynamic array's
        // underlying slice. The pointer of the copy in the dynamic array would then point to
        // the stack-allocated node instance, rather than the copy itself. The parent field of
        // the copy in the dynamic array will be set later
        const local_node = Node{ .value = value, .parent = undefined };
        try self.arr.*.append(self.allocator, local_node);

        // Get a subset of the slice underneath the dynamic array, to be able to modify the
        // node instance in the dynamic array itself (using `self.arr.*.get()` seems to return
        // a copy rather than the one actually in the dynamic array, and modifying a copy
        // doesn't achieve what's necessary for the node-pointing-to-parent-node to work).
        var arr_slice = if (self.arr.*.get_slice(self.count, self.count + 1)) |val| val else |_| {
            // This slice of a single element shoudl always be within the bounds of the array,
            // because the dynamic array has just been expanded by one element, and this is the
            // element we're getting a slice to. So, an `OutOfBounds` error should never be
            // returned. Hence, unreachable
            unreachable;
        };
        arr_slice[0].parent = &arr_slice[0];

        try self.map.*.put(self.allocator, value, self.count);
        self.count += 1;
    }

    pub fn find(self: UnionFind, value: u8) u8 {
        const idx = if (self.map.*.get(value)) |val| val else |_| {
            // TODO: Return appropriate error if requesting to find a value that doesn't exist
            // in the hash table. For now, panic.
            unreachable;
        };

        if (self.arr.*.get(idx)) |node| {
            if (node.parent.*.value == node.value) {
                return node.value;
            }

            // TODO: Handle when the parent pointer needs to be followed to the representative
            // of the set that the node belongs to. For now, panic.
            unreachable;
        } else |_| {
            // If the value has been mapped to a non-negative integer and put into the hash
            // table, then the array should be long enough for the non-negative integer to be a
            // valid index into the array. So, an `OutOfBounds` error shouldn't be returned
            // here, hence, unreachable.
            unreachable;
        }
    }
};

test "insert single element into union-find" {
    const allocator = std.testing.allocator;
    const value = 6;
    var union_find = try UnionFind.new(allocator);
    try union_find.insert(value);
    try std.testing.expectEqual(1, union_find.count);
    try union_find.free();
}

test "find single element in union-find" {
    const allocator = std.testing.allocator;
    const value = 6;
    var union_find = try UnionFind.new(allocator);

    // Insert single value into union-find
    try union_find.insert(value);

    // Find representative of set that the single value belongs to (should be itself)
    const representative = union_find.find(value);
    try std.testing.expectEqual(value, representative);

    // Free union-find
    try union_find.free();
}

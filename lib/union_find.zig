const std = @import("std");

const array = @import("array.zig");
const hash_table = @import("hash_table.zig");

pub const UnionFind = struct {
    /// Number of elements in the data structure
    count: usize,
    /// Underlying data structure to hold elements
    arr: *array.DynamicArray(usize),
    allocator: std.mem.Allocator,
    map: *hash_table.HashTable(usize),

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!UnionFind {
        const arr = try allocator.create(array.DynamicArray(usize));
        arr.* = try array.DynamicArray(usize).new(allocator, 0);
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
        try self.arr.*.append(self.allocator, self.count);
        try self.map.*.put(self.allocator, value, self.count);
        self.count += 1;
    }

    pub fn find(self: UnionFind, value: u8) u8 {
        const idx = if (self.map.*.get(value)) |val| val else |_| {
            // TODO: Return appropriate error if requesting to find a value that doesn't exist
            // in the hash table. For now, panic.
            unreachable;
        };

        if (self.arr.*.get(idx)) |parent_idx| {
            if (parent_idx == idx) {
                // The value stored at `idx` in the array is the same as the value which
                // `value` mapped to in the hash table. This means that the representative of
                // the set that `value` is in, is itself
                return value;
            }

            // TODO: If execution has reached there, this means that the representative of
            // `value` is not itself, and the root needs to be found.
            //
            // This is done by following the value stored at `idx` (using it as the index of
            // the "parent" of `value), and following the parents until the representative has
            // been found.
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

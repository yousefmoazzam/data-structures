const std = @import("std");

const array = @import("array.zig");

pub const UnionFind = struct {
    /// Number of elements in the data structure
    count: usize,
    /// Underlying data structure to hold elements
    arr: array.DynamicArray(u8),
    allocator: std.mem.Allocator,

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!UnionFind {
        return UnionFind{
            .arr = try array.DynamicArray(u8).new(allocator, 0),
            .count = 0,
            .allocator = allocator,
        };
    }

    pub fn insert(self: *UnionFind, value: u8) std.mem.Allocator.Error!void {
        try self.arr.append(self.allocator, value);
        self.count += 1;
    }
};

test "insert single element into union-find" {
    const allocator = std.testing.allocator;
    const value = 6;
    var union_find = try UnionFind.new(allocator);
    try union_find.insert(value);
    try std.testing.expectEqual(1, union_find.count);
}

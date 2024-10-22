const std = @import("std");

const array = @import("array.zig");
const hash_table = @import("hash_table.zig");

const Error = error{
    ElementNotFound,
};

pub const UnionFind = struct {
    /// Number of elements in the data structure
    count: usize,
    /// Underlying data structure to hold elements
    parents: *array.DynamicArray(usize),
    elements: *array.DynamicArray(u8),
    allocator: std.mem.Allocator,
    map: *hash_table.HashTable(usize),

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!UnionFind {
        const parents = try allocator.create(array.DynamicArray(usize));
        parents.* = try array.DynamicArray(usize).new(allocator, 0);
        const map = try allocator.create(hash_table.HashTable(usize));
        map.* = try hash_table.HashTable(usize).new(allocator);
        const elements = try allocator.create(array.DynamicArray(u8));
        elements.* = try array.DynamicArray(u8).new(allocator, 0);
        return UnionFind{
            .parents = parents,
            .count = 0,
            .allocator = allocator,
            .map = map,
            .elements = elements,
        };
    }

    pub fn free(self: *UnionFind) std.mem.Allocator.Error!void {
        try self.parents.*.free(self.allocator);
        self.allocator.destroy(self.parents);
        try self.map.*.free(self.allocator);
        self.allocator.destroy(self.map);
        try self.elements.*.free(self.allocator);
        self.allocator.destroy(self.elements);
    }

    pub fn insert(self: *UnionFind, value: u8) std.mem.Allocator.Error!void {
        try self.parents.*.append(self.allocator, self.count);
        try self.elements.*.append(self.allocator, value);
        try self.map.*.put(self.allocator, value, self.count);
        self.count += 1;
    }

    pub fn find(self: UnionFind, value: u8) Error!u8 {
        const idx = if (self.map.*.get(value)) |val| val else |_| {
            return Error.ElementNotFound;
        };

        if (self.parents.*.get(idx)) |parent_idx| {
            if (parent_idx == idx) {
                // The value stored at `idx` in the array is the same as the value which
                // `value` mapped to in the hash table. This means that the representative of
                // the set that `value` is in, is itself
                return value;
            }

            // If execution has reached there, this means that the representative of `value` is
            // not itself, and the root needs to be found.
            //
            // This is done by following the value stored at `idx` (using it as the index of
            // the "parent" of `value), and following the parents until the representative has
            // been found.
            var current_idx = parent_idx;
            var next_idx = parent_idx;
            while (true) {
                next_idx = if (self.parents.*.get(current_idx)) |val| val else |_| {
                    // All values stored in the underlying should be valid indices into the
                    // array, so an `OutOfBounds` error should never be returned. Hence,
                    // unreachable.
                    unreachable;
                };
                if (next_idx == current_idx) break;
                current_idx = next_idx;
            }

            const representative_idx = if (self.parents.*.get(current_idx)) |val| val else |_| unreachable;
            return if (self.elements.*.get(representative_idx)) |val| val else |_| {
                unreachable;
            };
        } else |_| {
            // If the value has been mapped to a non-negative integer and put into the hash
            // table, then the array should be long enough for the non-negative integer to be a
            // valid index into the array. So, an `OutOfBounds` error shouldn't be returned
            // here, hence, unreachable.
            unreachable;
        }
    }

    pub fn unify(self: *UnionFind, a: u8, b: u8) Error!void {
        if (a == b) {
            // Nothing to do.
            return;
        }

        // Need to make either:
        // - `a` the parent of `b`, or
        // - `b` the parent of `a`
        //
        // Arbitrarily, make the element which maps to smaller index the "parent"
        const a_idx = if (self.map.*.get(a)) |val| val else |_| {
            // Return error if trying to unify two elements where `a` isn't in the union-find.
            return Error.ElementNotFound;
        };
        const b_idx = if (self.map.*.get(b)) |val| val else |_| {
            // Return error if trying to unify two elements where `b` isn't in the union-find.
            return Error.ElementNotFound;
        };

        if (a_idx < b_idx) {
            if (self.parents.*.set(b_idx, a_idx)) |_| {} else |_| {
                // `b_idx` should be a valid index in the underlying array (since it came from
                // the hash table, which should contain within-bound array indices). So, an
                // `OutOfBounds` error shouldn't be possible here. Hence, unreachable.
                unreachable;
            }
        }

        if (b_idx < a_idx) {
            if (self.parents.*.set(a_idx, b_idx)) |_| {} else |_| {
                // Similar reasoning as above `else` clause being unreachble, just replacing
                // `b_idx` there with `a_idx` here.
                unreachable;
            }
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

test "unify two elements in union-find into the same set" {
    const allocator = std.testing.allocator;
    var union_find = try UnionFind.new(allocator);
    const values = [_]u8{ 3, 7 };

    // Insert both values into union-find
    for (values) |value| {
        try union_find.insert(value);
    }

    // Unify both values into the same set
    try union_find.unify(values[0], values[1]);

    // Verify that the two values in union-find have the same representative
    const rep_one = try union_find.find(values[0]);
    const rep_two = try union_find.find(values[1]);
    try std.testing.expectEqual(rep_one == rep_two, true);

    // Free union-find
    try union_find.free();
}

test "unify two elements in union-find into the same set, swapped inputs to unify method" {
    const allocator = std.testing.allocator;
    var union_find = try UnionFind.new(allocator);
    const values = [_]u8{ 3, 7 };

    // Insert both values into union-find
    for (values) |value| {
        try union_find.insert(value);
    }

    // Unify both values into the same set
    try union_find.unify(values[1], values[0]);

    // Verify that the two values in union-find have the same representative
    const rep_one = try union_find.find(values[0]);
    const rep_two = try union_find.find(values[1]);
    try std.testing.expectEqual(rep_one == rep_two, true);

    // Free union-find
    try union_find.free();
}

test "return error if finding element that doesn't exist in union-find" {
    const allocator = std.testing.allocator;
    var union_find = try UnionFind.new(allocator);
    const values = [_]u8{ 3, 7 };
    const non_existent_value = 9;

    // Insert values into union-find
    for (values) |value| {
        try union_find.insert(value);
    }

    // Attempt to find representative of non-existent value in union-find, and check an error
    // is returned
    const ret = union_find.find(non_existent_value);
    try std.testing.expectError(Error.ElementNotFound, ret);

    // Free union-find
    try union_find.free();
}

test "unifying an element in the union-find with itself keeps its parent as itself" {
    const allocator = std.testing.allocator;
    var union_find = try UnionFind.new(allocator);
    const values = [_]u8{ 3, 7 };

    // Insert values into union-find
    for (values) |value| {
        try union_find.insert(value);
    }

    // Unify an element with itself, and check nothing strange has happened with its parent
    // (ie, that its parent is still itself)
    try union_find.unify(values[0], values[0]);
    try std.testing.expectEqual(values[0], try union_find.find(values[0]));

    // Free union-find
    try union_find.free();
}

test "return error if trying to unify elements where left doesn't exist in union-find" {
    const allocator = std.testing.allocator;
    var union_find = try UnionFind.new(allocator);
    const values = [_]u8{ 3, 7 };
    const non_existent_value = 10;

    // Insert values into union-find
    for (values) |value| {
        try union_find.insert(value);
    }

    // Attempt to unify an existent element with a non-existent element, and check an error has
    // been returned
    const ret = union_find.unify(non_existent_value, values[0]);
    try std.testing.expectError(Error.ElementNotFound, ret);

    // Free union-find
    try union_find.free();
}

test "return error if trying to unify elements where right doesn't exist in union-find" {
    const allocator = std.testing.allocator;
    var union_find = try UnionFind.new(allocator);
    const values = [_]u8{ 3, 7 };
    const non_existent_value = 10;

    // Insert values into union-find
    for (values) |value| {
        try union_find.insert(value);
    }

    // Attempt to unify an existent element with a non-existent element, and check an error has
    // been returned
    const ret = union_find.unify(values[0], non_existent_value);
    try std.testing.expectError(Error.ElementNotFound, ret);

    // Free union-find
    try union_find.free();
}

const std = @import("std");

const list = @import("linked_list.zig");

/// Reduce `key` modulo `n`
fn modulo_hash(key: u8, n: usize) usize {
    return key % n;
}

/// Key-value pair "type constructor". Creates a map type which holds a key (of type `u8`) and
/// an associated value (of type `T`)
fn Map(comptime T: type) type {
    return struct {
        key: u8,
        value: T,

        const Self = @This();

        fn new(key: u8, value: T) Self {
            return Self{
                .key = key,
                .value = value,
            };
        }
    };
}

/// Hash table "type constructor". Creates a hash table type with keys of type `u8` and values
/// of type `T`
pub fn HashTable(comptime T: type) type {
    return struct {
        const Pair = Map(T);
        const Bucket = list.SinglyLinkedList(Pair);

        // Public
        size: usize,

        // Private / internal
        slice: []Bucket,

        pub fn KeyType() type {
            return u8;
        }

        pub fn ValueType() type {
            return T;
        }

        const Self = @This();

        pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!Self {
            const buckets = try allocator.alloc(Bucket, 0);
            return Self{
                .size = 0,
                .slice = buckets,
            };
        }

        pub fn free(self: *Self, allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
            for (self.slice) |*bucket| bucket.free(allocator);
            allocator.free(self.slice);
            self.slice = try allocator.alloc(Bucket, 0);
            self.size = 0;
        }

        pub fn put(self: *Self, allocator: std.mem.Allocator, key: u8, value: T) std.mem.Allocator.Error!void {
            if (self.size == 0) {
                self.slice = try allocator.alloc(Bucket, 5);
                for (self.slice) |*bucket| bucket.* = Bucket.new();
            }

            const hash = modulo_hash(key, self.slice.len);

            // Search bucket for the key that's been requested to be put into the hash table.
            // If it's found, the key-value pair already exists, so update the value rather
            // than appending to the bucket.
            const bucket = self.slice[hash];
            var traversal_ptr = bucket.head;
            var count: usize = 0;
            while (count < bucket.len) : (count += 1) {
                if (traversal_ptr.?.value.key == key) {
                    traversal_ptr.?.value.value = value;
                    return;
                }
            }

            // If execution has reached here then the given key wasn't found in the bucket
            // associated with the key's hash value, so the key-value pair doesn't exist in the
            // hash table yet. Thus, append the value to the bucket.
            const pair = Pair{ .key = key, .value = value };
            try self.slice[hash].append(allocator, pair);
            self.size += 1;
        }

        pub fn get(self: Self, key: u8) T {
            const hash = modulo_hash(key, self.slice.len);
            const bucket = self.slice[hash];

            // TODO: Assumes that the bucket associated with the hash value is not empty.
            // Handle this properly.
            if (bucket.len == 0) unreachable;

            // Check if the 0th pair in the bucket contains the value requested
            if (bucket.get(0)) |pair| {
                if (pair.key == key) return pair.value;
            } else |_| unreachable;

            // If execution has reached this far then the 0th element in the bucket didn't
            // contain the requested value, so scan through the bucket starting at index 1 and
            // search for the pair containing the requested value
            var traversal_ptr = bucket.head.?.next;
            var count: usize = 1;
            while (count < bucket.len) : (count += 1) {
                if (traversal_ptr.?.value.key == key) {
                    return traversal_ptr.?.value.value;
                }
                traversal_ptr = traversal_ptr.?.next;
            }

            // TODO: Properly handle trying to get value for non-existent key
            //
            // For now, to satisfy the return type needing a `T` returned on all paths of
            // execution in this function, return the 0th element in the bucket
            const pair = if (self.slice[hash].get(0)) |val| val else |_| unreachable;
            return pair.value;
        }
    };
}

test "create hash table type mapping u8 keys to u16 values" {
    const key_type = u8;
    const value_type = u16;
    const hash_table_type = HashTable(value_type);
    try std.testing.expectEqual(key_type, hash_table_type.KeyType());
    try std.testing.expectEqual(value_type, hash_table_type.ValueType());
}

test "create empty hash table" {
    const allocator = std.testing.allocator;
    const hash_table = try HashTable(u8).new(allocator);
    try std.testing.expectEqual(0, hash_table.size);
}

test "put single key-value pair into hash table" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    try hash_table.put(allocator, 0, 6);
    try std.testing.expectEqual(1, hash_table.size);
    try hash_table.free(allocator);
}

test "freeing non-empty hash table resets size to zero" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    try hash_table.put(allocator, 0, 6);
    try hash_table.free(allocator);
    try std.testing.expectEqual(0, hash_table.size);
}

test "get single value stored in hash table" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const key = 3;
    const value = 6;

    // Put key-value pair into hash table
    try hash_table.put(allocator, key, value);

    // Check that the value can be retrieved from the hash table using its associated key
    try std.testing.expectEqual(value, hash_table.get(key));

    // Free hash table
    try hash_table.free(allocator);
}

test "put multiple key-value pairs into hash table" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const keys = [_]u8{ 0, 1, 2, 3, 4, 5 };
    const values = [_]u8{ 18, 3, 56, 190, 22, 174 };

    // Put values into hash table
    for (keys, values) |k, v| {
        try hash_table.put(allocator, k, v);
    }

    // Check value associated with each key is as expected
    for (keys, values) |k, v| {
        try std.testing.expectEqual(v, hash_table.get(k));
    }

    // Free hash table
    try hash_table.free(allocator);
}

test "put existing key-value pair updates value" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const key = 3;
    const first_value = 1;
    const second_value = 6;

    // Put first value for key in hash table
    try hash_table.put(allocator, key, first_value);

    // Put second value for key in hash table
    try hash_table.put(allocator, key, second_value);

    // Check that the size hasn't changed, and that the value associated with the key has been
    // updated
    try std.testing.expectEqual(1, hash_table.size);
    try std.testing.expectEqual(second_value, hash_table.get(key));

    // Free hash table
    try hash_table.free(allocator);
}

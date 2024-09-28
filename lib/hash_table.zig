const std = @import("std");

/// Reduce `key` modulo `n`
fn modulo_hash(key: u8, n: usize) usize {
    return key % n;
}

/// Hash table "type constructor". Creates a hash table type with keys of type `u8` and values
/// of type `T`
pub fn HashTable(comptime T: type) type {
    return struct {
        // Public
        size: usize,

        // Private / internal
        slice: []T,

        pub fn KeyType() type {
            return u8;
        }

        pub fn ValueType() type {
            return T;
        }

        const Self = @This();

        pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!Self {
            const vals = try allocator.alloc(T, 0);
            return Self{
                .size = 0,
                .slice = vals,
            };
        }

        pub fn free(self: *Self, allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
            allocator.free(self.slice);
            self.slice = try allocator.alloc(T, 0);
            self.size = 0;
        }

        pub fn put(self: *Self, allocator: std.mem.Allocator, key: u8, value: T) std.mem.Allocator.Error!void {
            if (self.size == 0) {
                self.slice = try allocator.alloc(T, 5);
            }

            const hash = modulo_hash(key, self.slice.len);
            self.slice[hash] = value;
            self.size += 1;
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

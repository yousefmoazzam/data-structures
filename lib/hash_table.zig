const std = @import("std");

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

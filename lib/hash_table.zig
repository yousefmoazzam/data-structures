const std = @import("std");

/// Hash table "type constructor". Creates a hash table type with keys of type `u8` and values
/// of type `T`
pub fn HashTable(comptime T: type) type {
    return struct {
        pub fn KeyType() type {
            return u8;
        }

        pub fn ValueType() type {
            return T;
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

const std = @import("std");

const list = @import("linked_list.zig");

/// Reduce `key` modulo `n`
fn modulo_hash(key: u8, n: usize) usize {
    return key % n;
}

pub const Error = error{
    KeyNotFound,
    Empty,
};

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

        pub fn get(self: Self, key: u8) Error!T {
            if (self.slice.len == 0) return Error.Empty;

            const hash = modulo_hash(key, self.slice.len);
            const bucket = self.slice[hash];

            if (bucket.len == 0) return Error.KeyNotFound;

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

            // If execution has gotten this far then the requested key doesn't exist in the
            // hash table. Thus, return an error.
            return Error.KeyNotFound;
        }

        pub fn delete(self: *Self, allocator: std.mem.Allocator, key: u8) Error!void {
            if (self.slice.len == 0) return Error.Empty;

            const hash = modulo_hash(key, self.slice.len);
            // NOTE: Couldn't get this to work with just `var bucket = self.slice[hash]`, was
            // getting a segfault during `free()` call if `delete()` was called prior to it for
            // some unknown reason, so have gotten a pointer via `&self.slice[hash]` instead
            const bucket_ptr = &self.slice[hash];
            if (bucket_ptr.*.len == 0) return Error.KeyNotFound;

            // Check if the 0th pair in the bucket contains the key requested for deletion
            if (bucket_ptr.*.get(0)) |pair| {
                if (pair.key == key) {
                    // The bucket has been established to not have a length of zero. The
                    // hardcoded value of 0 being passed to `SinglyLinkedList(u8).delete()`
                    // means that the only way an `OutOfBounds` error can be returned is if the
                    // bucket has length zero, which can't happen here. Hence, unreachable.
                    if (bucket_ptr.*.delete(allocator, 0)) |_| {
                        self.size -= 1;
                        return;
                    } else |_| unreachable;
                }
            } else |_| {
                // The bucket has been established to not have a length of zero. The hardcoded
                // value of 0 being passed to `SinglyLinkedList(u8).get()` means that the only
                // way an `OutOfBounds` error can be returned is if the bucket has length zero,
                // which can't happen here. Hence, unreachable.
                unreachable;
            }

            // If execution has reached here, then the key-value pair is not the 0th element in
            // the bucket, so scan through the bucket and check if the pair is present
            var traversal_ptr = bucket_ptr.*.head.?.next;
            var count: usize = 1;
            while (traversal_ptr != null) : (count += 1) {
                if (traversal_ptr.?.*.value.key == key) {
                    if (bucket_ptr.*.delete(allocator, count)) |_| {
                        self.size -= 1;
                        return;
                    } else |_| {
                        // We have been able to check the key stored in the node at index
                        // `count` in the bucket, so the node must exist to be deleted. This
                        // means that an `OutOfBounds` error can't be returned by
                        // `SinglyLinkedList(T).delete()`. Hence, unreachable.
                        unreachable;
                    }
                }
                traversal_ptr = traversal_ptr.?.next;
            }

            // If execution has reached here, then the bucket was non-empty but the key wasn't
            // found, so return a "key not found" error
            return Error.KeyNotFound;
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

test "return error if getting non-existent key-value pair and buckets all populated" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const existent_keys = [_]u8{ 0, 1, 2, 3, 4 };
    const non_existent_key = 5;
    const values = [_]u8{ 29, 10, 33, 21, 64 };

    // Put key-value pairs in hash table
    for (existent_keys, values) |k, v| {
        try hash_table.put(allocator, k, v);
    }

    // Attempt to get non-existent key and check that an error is returned
    const ret = hash_table.get(non_existent_key);
    try std.testing.expectEqual(Error.KeyNotFound, ret);

    // Free hash table
    try hash_table.free(allocator);
}

test "return error if getting non-existent key-value pair from empty bucket" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const existent_keys = [_]u8{ 0, 1, 2, 3 };
    const non_existent_key = 4;
    const values = [_]u8{ 6, 12, 45, 7 };

    // Put key-value pairs in hash table
    for (existent_keys, values) |k, v| {
        try hash_table.put(allocator, k, v);
    }

    // Attempt to get non-existent key associated with empty bucket and check that an error is
    // returned
    const ret = hash_table.get(non_existent_key);
    try std.testing.expectError(Error.KeyNotFound, ret);

    // Free hash table
    try hash_table.free(allocator);
}

test "return error if getting key-value pair from empty hash table" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const ret = hash_table.get(0);
    try std.testing.expectError(Error.Empty, ret);
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

test "return error if deleting key-value pair from empty hash table" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const ret = hash_table.delete(allocator, 0);
    try std.testing.expectError(Error.Empty, ret);
}

test "return error if deleting non-existent key-value pair from empty bucket" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const existent_keys = [_]u8{ 0, 1, 2, 3 };
    const non_existent_key = 4;
    const values = [_]u8{ 41, 9, 6, 54 };

    // Put key-value pairs into hash table
    for (existent_keys, values) |k, v| {
        try hash_table.put(allocator, k, v);
    }

    // Attempt to delete non-existent key and check that an error is returned
    const ret = hash_table.delete(allocator, non_existent_key);
    try std.testing.expectError(Error.KeyNotFound, ret);

    // Free hash table
    try hash_table.free(allocator);
}

test "delete single key-value pair existing in hash table" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const key = 3;
    const value = 6;

    // Put key-value pair into hash table
    try hash_table.put(allocator, key, value);

    // Delete key-value pair from hash table
    try hash_table.delete(allocator, key);

    // Check that the size of the hash table has reduced back to zero
    try std.testing.expectEqual(0, hash_table.size);

    // Free hash table
    try hash_table.free(allocator);
}

test "delete multiple key-value pairs existing in hash table" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const keys = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    const values = [_]u8{ 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 };
    const indices_of_keys_to_keep = [_]u8{ 0, 2, 3, 4, 6, 7, 8, 10 };
    const indices_of_keys_to_delete = [_]u8{ 1, 5, 9 };

    // Put key-value pairs into hash table
    for (keys, values) |k, v| {
        try hash_table.put(allocator, k, v);
    }

    // Delete multiple key-value pairs
    for (indices_of_keys_to_delete) |i| {
        try hash_table.delete(allocator, keys[i]);
    }

    // Check that a `KeyNotFound` error is returned when trying to get the deleted key-value
    // pairs
    for (indices_of_keys_to_delete) |i| {
        try std.testing.expectError(Error.KeyNotFound, hash_table.get(keys[i]));
    }

    // Check that key-value pairs not requested to be deleted from hash table are still in the
    // hash table
    for (indices_of_keys_to_keep) |i| {
        try std.testing.expectEqual(values[i], try hash_table.get(keys[i]));
    }

    // Free hash table
    try hash_table.free(allocator);
}

test "return error if deleting non-existent key-value pair from non-empty bucket" {
    const allocator = std.testing.allocator;
    var hash_table = try HashTable(u8).new(allocator);
    const keys = [_]u8{ 0, 1, 2, 3, 4 };
    const values = [_]u8{ 0, 5, 10, 15, 20 };
    const non_existent_key = 5;

    // Put key-value pairs into hash table
    for (keys, values) |k, v| {
        try hash_table.put(allocator, k, v);
    }

    // Try deleting non-existent key in non-empty bucket and check an error is returned
    const ret = hash_table.delete(allocator, non_existent_key);
    try std.testing.expectError(Error.KeyNotFound, ret);

    // Free hash table
    try hash_table.free(allocator);
}

const std = @import("std");

const DynamicArrayError = error{
    OutOfBounds,
};

const DynamicArray = struct {
    // Length of the dynamic array as seen by the user
    len: usize,
    // Slice of internal static array used to provide the dynamic array
    slice: []u8,

    pub fn new(allocator: std.mem.Allocator, len: usize) std.mem.Allocator.Error!DynamicArray {
        const slice = try allocator.alloc(u8, len);
        return DynamicArray{
            .len = len,
            .slice = slice,
        };
    }

    pub fn free(self: DynamicArray, allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        allocator.free(self.slice);
    }

    pub fn set(self: DynamicArray, idx: usize, value: u8) DynamicArrayError!void {
        if (idx >= self.slice.len) {
            return DynamicArrayError.OutOfBounds;
        }
        self.slice[idx] = value;
    }

    pub fn get(self: DynamicArray, idx: usize) DynamicArrayError!u8 {
        if (idx >= self.slice.len) {
            return DynamicArrayError.OutOfBounds;
        }
        return self.slice[idx];
    }

    pub fn get_slice(self: DynamicArray, start: usize, stop: usize) DynamicArrayError![]u8 {
        if (stop >= self.slice.len) {
            return DynamicArrayError.OutOfBounds;
        }
        return self.slice[start..stop];
    }
};

test "create dynamic array with given length" {
    const len = 5;
    const allocator = std.testing.allocator;
    const arr = try DynamicArray.new(allocator, len);
    try std.testing.expect(arr.len == len);
    try arr.free(allocator);
}

test "set and get value in dynamic array" {
    const len = 1;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray.new(allocator, len);
    const new_value = 5;
    try arr.set(0, new_value);
    const val = try arr.get(0);
    try std.testing.expect(val == new_value);
    try arr.free(allocator);
}

test "return error on out of bounds get index" {
    const len = 1;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray.new(allocator, len);
    const ret = arr.get(1);
    try std.testing.expectError(DynamicArrayError.OutOfBounds, ret);
    try arr.free(allocator);
}

test "return error on out of bounds set index" {
    const len = 1;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray.new(allocator, len);
    const ret = arr.set(1, 5);
    try std.testing.expectError(DynamicArrayError.OutOfBounds, ret);
    try arr.free(allocator);
}

test "get slice of dynamic array" {
    const len = 5;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray.new(allocator, len);
    const expected_values = [_]u8{ 1, 2, 3 };
    const shift = 1;

    // Set values in the dynamic array to check later in the slice of the array
    for (expected_values, 0..) |value, i| {
        try arr.set(i + shift, value);
    }

    const slice = try arr.get_slice(shift, expected_values.len + shift);
    try std.testing.expectEqual(3, slice.len);

    // Compare values in slice to expected values
    for (slice, 0..) |value, i| {
        try std.testing.expectEqual(expected_values[i], value);
    }

    try arr.free(allocator);
}

test "return error on out of bounds slice" {
    const len = 2;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray.new(allocator, len);
    const ret = arr.get_slice(0, len);
    try std.testing.expectError(DynamicArrayError.OutOfBounds, ret);
    try arr.free(allocator);
}

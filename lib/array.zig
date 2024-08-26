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
        const slice = try allocator.alloc(u8, len * 2);
        return DynamicArray{
            .len = len,
            .slice = slice,
        };
    }

    pub fn free(self: DynamicArray, allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        allocator.free(self.slice);
    }

    pub fn set(self: DynamicArray, idx: usize, value: u8) DynamicArrayError!void {
        if (idx >= self.len) {
            return DynamicArrayError.OutOfBounds;
        }
        self.slice[idx] = value;
    }

    pub fn get(self: DynamicArray, idx: usize) DynamicArrayError!u8 {
        if (idx >= self.len) {
            return DynamicArrayError.OutOfBounds;
        }
        return self.slice[idx];
    }

    pub fn get_slice(self: DynamicArray, start: usize, stop: usize) DynamicArrayError![]u8 {
        if (stop >= self.len) {
            return DynamicArrayError.OutOfBounds;
        }
        return self.slice[start..stop];
    }

    pub fn insert(self: *DynamicArray, allocator: std.mem.Allocator, value: u8) std.mem.Allocator.Error!void {
        if (self.len == self.slice.len) {
            // Allocate new larger slice
            const slice = try allocator.alloc(u8, self.len * 2);
            // Copy values from existing slice into new slice
            for (0..self.slice.len) |i| {
                slice[i] = self.slice[i];
            }
            // Set newly inserted element
            slice[self.slice.len] = value;
            // Free old slice and assign newly created one
            allocator.free(self.slice);
            self.slice = slice;
        } else {
            self.slice[self.len] = value;
        }
        self.len += 1;
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

test "insert element into array" {
    const startingLen = 1;
    const allocator = std.testing.allocator;
    const existingValue = 1;
    const insertedValue = 5;
    var arr = try DynamicArray.new(allocator, startingLen);

    // Set value in array before inserting a new value
    try arr.set(0, existingValue);

    // Insert new value into array
    try arr.insert(allocator, insertedValue);

    // Check that the array length has increased by one
    try std.testing.expectEqual(arr.len, startingLen + 1);

    // Check original value is still present in the array
    const value = try arr.get(0);
    try std.testing.expectEqual(existingValue, value);

    // Check newly inserted element is at the end of the array
    const endValue = try arr.get(startingLen);
    try std.testing.expectEqual(insertedValue, endValue);

    // Free testing array
    try arr.free(allocator);
}

test "insert elements into array with no space left" {
    const startingLen = 1;
    const allocator = std.testing.allocator;
    const existingValue = 1;
    const valuesToInsert = [_]u8{ 1, 2, 3 };
    var arr = try DynamicArray.new(allocator, startingLen);

    // Set value in array before inserting a new value
    try arr.set(0, existingValue);

    // Insert new values into array
    for (valuesToInsert) |value| {
        try arr.insert(allocator, value);
    }

    // Check that the array length has increased
    try std.testing.expectEqual(arr.len, startingLen + valuesToInsert.len);

    // Check original value is still present in the array
    const value = try arr.get(0);
    try std.testing.expectEqual(existingValue, value);

    // Check newly inserted elements are in the array
    for (1..startingLen + valuesToInsert.len) |i| {
        const insertedValue = try arr.get(i);
        try std.testing.expectEqual(valuesToInsert[i - 1], insertedValue);
    }

    // Free testing array
    try arr.free(allocator);
}

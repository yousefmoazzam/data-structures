const std = @import("std");

const DynamicArrayError = error{
    OutOfBounds,
};

pub fn DynamicArray(comptime T: type) type {
    return struct {
        // Length of the dynamic array as seen by the user
        len: usize,
        // Slice of internal static array used to provide the dynamic array
        slice: []T,

        const Self = @This();

        pub fn new(allocator: std.mem.Allocator, len: usize) std.mem.Allocator.Error!Self {
            const slice = try allocator.alloc(T, len);
            return Self{
                .len = len,
                .slice = slice,
            };
        }

        pub fn free(self: *Self, allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
            allocator.free(self.slice);
            self.slice = try allocator.alloc(T, 0);
            self.len = 0;
        }

        pub fn set(self: Self, idx: usize, value: T) DynamicArrayError!void {
            if (idx >= self.len) {
                return DynamicArrayError.OutOfBounds;
            }
            self.slice[idx] = value;
        }

        pub fn get(self: Self, idx: usize) DynamicArrayError!T {
            if (idx >= self.len) {
                return DynamicArrayError.OutOfBounds;
            }
            return self.slice[idx];
        }

        pub fn get_slice(self: Self, start: usize, stop: usize) DynamicArrayError![]T {
            if (stop > self.len) {
                return DynamicArrayError.OutOfBounds;
            }
            return self.slice[start..stop];
        }

        pub fn append(self: *Self, allocator: std.mem.Allocator, value: T) std.mem.Allocator.Error!void {
            if (self.len == self.slice.len) {
                // Allocate new larger slice
                const new_len = if (self.len == 0) 2 else self.len * 2;
                const slice = try allocator.alloc(T, new_len);
                // Copy values from existing slice into new slice
                for (0..self.slice.len) |i| {
                    slice[i] = self.slice[i];
                }
                // Set newly appended element
                slice[self.slice.len] = value;
                // Free old slice and assign newly created one
                allocator.free(self.slice);
                self.slice = slice;
            } else {
                self.slice[self.len] = value;
            }
            self.len += 1;
        }

        pub fn insert(self: *Self, allocator: std.mem.Allocator, idx: usize, value: T) (std.mem.Allocator.Error || DynamicArrayError)!void {
            if (idx >= self.len) {
                return DynamicArrayError.OutOfBounds;
            }

            if (self.len == self.slice.len) {
                // Allocate new larger slice
                const slice = try allocator.alloc(T, self.len * 2);
                // Copy values from 0 to `idx` to the new slice
                for (0..idx) |i| {
                    slice[i] = self.slice[i];
                }
                // Insert new value
                slice[idx] = value;
                // Copy the remaining values from the old slice into the new slice
                for (idx + 1..self.len + 1) |i| {
                    slice[i] = self.slice[i - 1];
                }
                // Free old slice
                allocator.free(self.slice);
                self.slice = slice;
            } else {
                // For indices after `idx`, shift their contents to the right by 1
                for (0..self.len - idx) |i| {
                    self.slice[self.len - i] = self.slice[self.len - i - 1];
                }
                // Insert new value at given index
                self.slice[idx] = value;
            }
            self.len += 1;
        }

        pub fn delete(self: *Self, idx: usize) DynamicArrayError!void {
            if (idx >= self.len) {
                return DynamicArrayError.OutOfBounds;
            }

            // Shift elements on RHS of `idx` down by 1 position
            for (idx..self.len - 1) |i| {
                self.slice[i] = self.slice[i + 1];
            }

            // Decrease length by 1 to reflect deleted element
            self.len -= 1;
        }
    };
}

test "create dynamic array with given length" {
    const len = 5;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, len);
    try std.testing.expect(arr.len == len);
    try arr.free(allocator);
}

test "set and get value in dynamic array" {
    const len = 1;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, len);
    const new_value = 5;
    try arr.set(0, new_value);
    const val = try arr.get(0);
    try std.testing.expect(val == new_value);
    try arr.free(allocator);
}

test "return error on out of bounds get index" {
    const len = 1;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, len);
    const ret = arr.get(1);
    try std.testing.expectError(DynamicArrayError.OutOfBounds, ret);
    try arr.free(allocator);
}

test "return error on out of bounds set index" {
    const len = 1;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, len);
    const ret = arr.set(1, 5);
    try std.testing.expectError(DynamicArrayError.OutOfBounds, ret);
    try arr.free(allocator);
}

test "get slice of dynamic array" {
    const len = 5;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, len);
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

test "get slice to full data underneath dynamic array" {
    const len = 4;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, len);
    const values = [_]u8{ 1, 2, 3, 4 };

    // Set values in the dynamic array to check later in the slice of the array
    for (0..values.len) |i| {
        try arr.set(i, values[i]);
    }

    // Get slice and check that the length matches the full data
    const slice = try arr.get_slice(0, len);
    try std.testing.expectEqual(len, slice.len);

    // Compare values in slice to expected values
    for (slice, 0..) |value, i| {
        try std.testing.expectEqual(values[i], value);
    }

    // Free array
    try arr.free(allocator);
}

test "return error on out of bounds slice" {
    const len = 2;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, len);
    const ret = arr.get_slice(0, len + 1);
    try std.testing.expectError(DynamicArrayError.OutOfBounds, ret);
    try arr.free(allocator);
}

test "append element to empty array" {
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, 0);
    const value = 5;
    try arr.append(allocator, value);
    try std.testing.expectEqual(1, arr.len);
    try std.testing.expectEqual(value, arr.get(0));
    try arr.free(allocator);
}

test "append element to array" {
    const startingLen = 1;
    const allocator = std.testing.allocator;
    const existingValue = 1;
    const valueToAppend = 5;
    var arr = try DynamicArray(u8).new(allocator, startingLen);

    // Set value in array before appending a new value
    try arr.set(0, existingValue);

    // Append new value to array
    try arr.append(allocator, valueToAppend);

    // Check that the array length has increased by one
    try std.testing.expectEqual(arr.len, startingLen + 1);

    // Check original value is still present in the array
    const value = try arr.get(0);
    try std.testing.expectEqual(existingValue, value);

    // Check newly appended element is at the end of the array
    const endValue = try arr.get(startingLen);
    try std.testing.expectEqual(valueToAppend, endValue);

    // Free testing array
    try arr.free(allocator);
}

test "append elements to array with no space left" {
    const startingLen = 1;
    const allocator = std.testing.allocator;
    const existingValue = 1;
    const valuesToAppend = [_]u8{ 1, 2, 3 };
    var arr = try DynamicArray(u8).new(allocator, startingLen);

    // Set value in array before appending new values
    try arr.set(0, existingValue);

    // Append new values to array
    for (valuesToAppend) |value| {
        try arr.append(allocator, value);
    }

    // Check that the array length has increased
    try std.testing.expectEqual(arr.len, startingLen + valuesToAppend.len);

    // Check original value is still present in the array
    const value = try arr.get(0);
    try std.testing.expectEqual(existingValue, value);

    // Check newly appended elements are in the array
    for (1..startingLen + valuesToAppend.len) |i| {
        const appendedValue = try arr.get(i);
        try std.testing.expectEqual(valuesToAppend[i - 1], appendedValue);
    }

    // Free testing array
    try arr.free(allocator);
}

test "insert element at start of array" {
    const startlingLen = 3;
    const allocator = std.testing.allocator;
    const existingValues = [_]u8{ 2, 3, 4 };
    const valueToInsert = 1;
    var arr = try DynamicArray(u8).new(allocator, startlingLen);

    // Set values in array before inserting new value
    for (existingValues, 0..) |value, i| {
        try arr.set(i, value);
    }

    // Insert new value at start of array
    try arr.insert(allocator, 0, valueToInsert);

    // Check that the array length has increased by one
    try std.testing.expectEqual(arr.len, startlingLen + 1);

    // Check original values are still present in the array
    for (0..existingValues.len) |i| {
        // Shift by 1, since original values should have been shifted up by 1 due to the new
        // value that was inserted at index 0
        const value = try arr.get(i + 1);
        try std.testing.expectEqual(existingValues[i], value);
    }

    // Check newly inserted element is at the beginning of the array
    const startValue = try arr.get(0);
    try std.testing.expectEqual(valueToInsert, startValue);

    // Free testing array
    try arr.free(allocator);
}

test "return error on out of bounds insert" {
    const startingLen = 2;
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, startingLen);
    const ret = arr.insert(allocator, startingLen, 0);
    try std.testing.expectError(DynamicArrayError.OutOfBounds, ret);
    try arr.free(allocator);
}

test "insert element at non-zero index of array" {
    const startlingLen = 3;
    const allocator = std.testing.allocator;
    const existingValues = [_]u8{ 2, 3, 4 };
    const valueToInsert = 1;
    const nonZeroIdx = 1;
    var arr = try DynamicArray(u8).new(allocator, startlingLen);

    // Set values in array before inserting new value
    for (existingValues, 0..) |value, i| {
        try arr.set(i, value);
    }

    // Insert new value at non-zero index in array
    try arr.insert(allocator, nonZeroIdx, valueToInsert);

    // Check that the array length has increased by one
    try std.testing.expectEqual(arr.len, startlingLen + 1);

    // Check original values are still present in the array at indices 0, 2, 3
    try std.testing.expectEqual(existingValues[0], try arr.get(0));
    try std.testing.expectEqual(existingValues[1], try arr.get(2));
    try std.testing.expectEqual(existingValues[2], try arr.get(3));

    // Check newly inserted element is at index `nonZeroIdx` in the array
    try std.testing.expectEqual(valueToInsert, try arr.get(nonZeroIdx));

    // Free testing array
    try arr.free(allocator);
}

test "insert elements into array with no space left" {
    const startingLen = 2;
    const allocator = std.testing.allocator;
    const existingValues = [_]u8{ 0, 1 };
    const valuesToInsert = [_]u8{ 2, 3, 4 };
    var arr = try DynamicArray(u8).new(allocator, startingLen);

    // Set value in array before inserting a new value
    for (0..existingValues.len) |i| {
        try arr.set(i, existingValues[i]);
    }

    // Insert new values into array
    for (0..valuesToInsert.len) |i| {
        try arr.insert(allocator, i, valuesToInsert[i]);
    }

    // Check that the array length has increased
    try std.testing.expectEqual(arr.len, startingLen + valuesToInsert.len);

    // Check original values are still present in the array
    for (0..existingValues.len - 1) |i| {
        // Offset by the number of values inserted at the start of the array
        const value = try arr.get(i + valuesToInsert.len);
        try std.testing.expectEqual(existingValues[i], value);
    }

    // Check newly inserted elements are in the array
    for (0..valuesToInsert.len - 1) |i| {
        const value = try arr.get(i);
        try std.testing.expectEqual(valuesToInsert[i], value);
    }

    // Free testing array
    try arr.free(allocator);
}

test "return error on out of bounds delete" {
    const startingLen = 2;
    const allocator = std.testing.allocator;
    const outOfBoundsIdx = 2;
    var arr = try DynamicArray(u8).new(allocator, startingLen);

    // Attempt to delete element at out of bounds index
    const ret = arr.delete(outOfBoundsIdx);
    try std.testing.expectError(DynamicArrayError.OutOfBounds, ret);

    // Free testing array
    try arr.free(allocator);
}

test "delete element at start of array" {
    const startingLen = 3;
    const allocator = std.testing.allocator;
    const existingValues = [_]u8{ 0, 1, 2 };
    var arr = try DynamicArray(u8).new(allocator, startingLen);

    // Set values in array before deletion
    for (0..existingValues.len - 1) |i| {
        try arr.set(i, existingValues[i]);
    }

    // Delete element at index 0
    try arr.delete(0);

    // Check array length has decreased by 1
    try std.testing.expectEqual(startingLen - 1, arr.len);

    // Check the expected values are still in the array
    for (0..existingValues.len - 2) |i| {
        // Shift index used for `existingValues` due to deletion of 0th element from the array
        try std.testing.expectEqual(try arr.get(i), existingValues[i + 1]);
    }

    // Free testing array
    try arr.free(allocator);
}

test "freeing non-empty array resets length to zero" {
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, 0);
    const values = [_]u8{ 1, 2, 3 };

    // Append values to array
    for (values) |value| {
        try arr.append(allocator, value);
    }

    // Free array
    try arr.free(allocator);

    // Check length of array is reset to zero
    try std.testing.expectEqual(0, arr.len);
}

test "reuse array after free" {
    const allocator = std.testing.allocator;
    var arr = try DynamicArray(u8).new(allocator, 0);
    const values = [_]u8{ 2, 3 };

    // Append values to array
    for (values) |value| {
        try arr.append(allocator, value);
    }

    // Free array
    try arr.free(allocator);

    // Reuse array by re-appending values
    for (values) |value| {
        try arr.append(allocator, value);
    }

    // Check length and elements are as expected
    try std.testing.expectEqual(values.len, arr.len);
    for (0..values.len) |i| {
        try std.testing.expectEqual(values[i], try arr.get(i));
    }

    // Free array to avoid memory leak causing failing test
    try arr.free(allocator);
}

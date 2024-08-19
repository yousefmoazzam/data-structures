const std = @import("std");

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

    pub fn set(self: DynamicArray, idx: usize, value: u8) void {
        self.slice[idx] = value;
    }

    pub fn get(self: DynamicArray, idx: usize) u8 {
        return self.slice[idx];
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
    arr.set(0, new_value);
    try std.testing.expect(arr.get(0) == new_value);
    try arr.free(allocator);
}

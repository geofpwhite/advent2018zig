const std = @import("std");
const parse = @import("util.zig").parse;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d5/input.txt");
    // var lines = try parse(allocator, "d4/test.txt");
    var line = lines.next().?;
    _ = try part1(allocator, &line, true);

    var lines_again = try parse(allocator, "d5/input.txt");
    var line_again = lines_again.next().?;

    try part2(allocator, &line_again);
}

pub fn part1(allocator: std.mem.Allocator, line: *[]const u8, print_end: bool) !usize {
    var old_len = line.len;
    line.* = try react(allocator, line);

    while (line.len != old_len) {
        old_len = line.len;
        line.* = try react(allocator, line);
    }
    if (print_end)
        std.debug.print("{d}\n", .{line.len});
    return line.len;
}
pub fn part2(allocator: std.mem.Allocator, line: *[]const u8) !void {
    var old_len = line.len;
    line.* = try react(allocator, line);

    while (line.len != old_len) {
        old_len = line.len;
        line.* = try react(allocator, line);
    }
    var min: usize = std.math.maxInt(usize);
    for ('a'..'z') |char| {
        var line_without = try remove_as_new(allocator, line, @intCast(char));
        const size = try part1(allocator, &line_without, false);
        if (size < min) {
            min = size;
        }
    }
    std.debug.print("{d}\n", .{min});
}

pub fn react(allocator: std.mem.Allocator, line: *[]const u8) ![]const u8 {
    var new_line: std.ArrayList(u8) = .empty;
    var index: usize = 0;
    while (line.len != 0 and index < line.len - 1) {
        const char: i64 = @intCast(line.*[index]);
        const char_next: i64 = @intCast(line.*[index + 1]);
        const diff: i64 = char - char_next;
        if (diff == 32 or diff == -32) {
            index += 2;
            continue;
        }

        try new_line.append(allocator, @intCast(char));
        index += 1;
    }
    if (line.len > 0) {
        try new_line.append(allocator, line.*[line.len - 1]);
    }

    return new_line.items;
}

pub fn remove_as_new(allocator: std.mem.Allocator, line: *[]const u8, lowercase_char_to_remove: u8) ![]const u8 {
    var new_line: std.ArrayList(u8) = .empty;
    for (line.*) |char| {
        if (char != lowercase_char_to_remove and char != lowercase_char_to_remove - 32)
            try new_line.append(allocator, char);
    }
    return new_line.items;
}

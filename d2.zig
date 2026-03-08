const std = @import("std");
const parse = @import("util.zig").parse;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d2/input.txt");
    try part1(&lines);
    lines.reset();
    const maybe = part2(&lines);
    if (maybe) |line| {
        std.debug.print("{s}\n", .{line});
    }
}

pub fn part1(lines: *std.mem.SplitIterator(u8, .any)) !void {
    var alphabet_count = std.mem.zeroes([26]i64);
    var twos_count: i64 = 0;
    var threes_count: i64 = 0;
    while (lines.next()) |line| {
        for (line) |char| {
            if (char >= 'a' and char <= 'z') {
                alphabet_count[char - 'a'] += 1;
            }
        }
        var twos = false;
        var threes = false;
        for (alphabet_count) |count| {
            if (count == 2 and !twos) {
                twos = true;
                twos_count += 1;
            }
            if (count == 3 and !threes) {
                threes = true;
                threes_count += 1;
            }
        }
        @memset(&alphabet_count, 0);
    }
    std.debug.print("checksum: {d}\n", .{twos_count * threes_count});
}

pub fn part2(lines: *std.mem.SplitIterator(u8, .any)) ?[]const u8 {
    var line_copy = lines.*;
    var index: usize = 0;
    while (lines.next()) |line| {
        line_copy.reset();
        for (0..index) |_| {
            _ = line_copy.next();
        }
        while (line_copy.next()) |line2| {
            const diff_and_index = diff(line, line2);
            if (diff_and_index[0] == 1) {
                std.debug.print("{d}\n", .{diff_and_index[1]});
                return line;
            }
        }
        index += 1;
    }
    return null;
}

pub fn diff(string1: []const u8, string2: []const u8) [2]i64 {
    if (string1.len != string2.len) {
        return [2]i64{ 0, 0 };
    }
    var diff_count: i64 = 0;
    var last_diff: i64 = 0;
    var index: i64 = 0;
    for (string1, string2) |c1, c2| {
        if (c1 != c2) {
            diff_count += 1;
            last_diff = index;
        }
        index += 1;
    }
    return [2]i64{ diff_count, last_diff };
}

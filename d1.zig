const std = @import("std");
const parse = @import("./util.zig").parse;
pub fn part2(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !void {
    var map = std.AutoArrayHashMap(i64, i64).init(allocator);
    var cur: i64 = 0;
    var skip_check: bool = false;
    defer map.deinit();
    while (lines.next()) |line| {
        if (map.get(cur) != null and !skip_check) {
            std.debug.print("Found duplicate: {d}\n", .{cur});
            return;
        }
        skip_check = false;
        try map.put(cur, 1);
        if (line.len == 0) {
            lines.reset();
            skip_check = true;
            continue;
        }
        if (line[0] == '-') {
            cur -= std.fmt.parseInt(i64, line[1..], 10) catch 0;

            continue;
        }
        cur += std.fmt.parseInt(i64, line[1..], 10) catch 0;
    }
}
pub fn part1(lines: *std.mem.SplitIterator(u8, .any)) !void {
    var cur: i64 = 0;
    var count: i64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        count += 1;
        if (line[0] == '-') {
            std.debug.print("{s} is negative, count {d}\n", .{ line, count });
            cur -= std.fmt.parseInt(i64, line[1..], 10) catch 0;
            continue;
        }
        std.debug.print("{s}, count {d}\n", .{ line, count });
        cur += std.fmt.parseInt(i64, line[1..], 10) catch 0;
    }
    std.debug.print("{d}", .{cur});
}
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d1/input.txt");
    try part1(&lines);
    lines.reset();
    try part2(allocator, &lines);
}

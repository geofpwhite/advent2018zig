const std = @import("std");
const parse = @import("util.zig").parse;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d3/input.txt");
    // var lines = try parse(allocator, "d3/test.txt");
    try part1and2(allocator, &lines);
    // lines.reset();
    // try part2(allocator, &lines);
}

pub fn parse_claims(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !std.ArrayList(claim) {
    var ary: std.ArrayList(claim) = .empty;
    var i: usize = 0;
    while (lines.next()) |line| {
        i += 1;
        if (line.len <= 1) {
            continue;
        }
        var nums = std.mem.splitAny(u8, line, "@ ,:x");
        _ = nums.next();
        var index: i64 = 0;
        var c = claim{
            .min_x = -1,
            .max_x = -1,
            .min_y = -1,
            .max_y = -1,
        };
        // std.debug.print("{s}", .{nums.buffer});
        while (nums.next()) |num_string| {
            if (num_string.len > 0) {
                // std.debug.print("{s} numstring \n", .{num_string});
                const num = std.fmt.parseInt(i64, std.mem.trim(u8, num_string, "\r\n"), 10) catch -1;

                switch (index) {
                    0 => c.min_x = num,
                    1 => c.min_y = num,
                    2 => c.max_x = c.min_x + num,
                    3 => c.max_y = c.min_y + num,
                    else => break,
                }
                index += 1;
            }
        }
        try ary.append(allocator, c);
    }
    return ary;
}

pub fn part1and2(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !void {
    var max_x: usize = 0;
    var max_y: usize = 0;
    var ary = try parse_claims(allocator, lines);
    defer ary.deinit(allocator);
    for (ary.items) |c| {
        if (c.max_x > max_x) {
            max_x = @intCast(c.max_x);
        }
        if (c.max_y > max_y) {
            max_y = @intCast(c.max_y);
        }
    }
    var memo: [][]usize = try allocator.alloc([]usize, max_x);
    for (memo) |*row| {
        row.* = try allocator.alloc(usize, max_y);
        @memset(row.*, 0);
    }
    defer {
        for (memo) |*row| {
            allocator.free(row.*);
        }
        allocator.free(memo);
    }

    for (ary.items) |cl| {
        for (@intCast(cl.min_x)..@intCast(cl.max_x)) |i| {
            for (@intCast(cl.min_y)..@intCast(cl.max_y)) |j| {
                memo[i][j] += 1;
            }
        }
    }
    var intersect_area: usize = 0;
    for (0..max_x) |i| {
        for (0..max_y) |j| {
            if (memo[i][j] > 1) {
                intersect_area += 1;
            }
        }
    }
    std.debug.print("{d}\n", .{intersect_area});

    outer: for (ary.items, 0..ary.items.len) |cl, claimNumber| {
        for (@intCast(cl.min_x)..@intCast(cl.max_x)) |i| {
            for (@intCast(cl.min_y)..@intCast(cl.max_y)) |j| {
                if (memo[i][j] > 1) {
                    continue :outer;
                }
            }
        }
        std.debug.print("{d}\n", .{claimNumber + 1});
        // break;
    }
}

const claim = struct {
    min_x: i64,
    max_x: i64,
    min_y: i64,
    max_y: i64,

    pub fn eql(self: claim, other: claim) bool {
        return (self.min_x == other.min_x and
            self.max_x == other.max_x and
            self.min_y == other.min_y and
            self.max_y == other.max_y);
    }

    pub fn area(self: claim) i64 {
        return (self.max_x - self.min_x) * (self.max_y - self.min_y);
    }
};

const coord = struct {
    x: i64,
    y: i64,
};

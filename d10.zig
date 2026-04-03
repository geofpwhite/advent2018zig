const std = @import("std");
const parse = @import("util.zig").parse;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d10/input.txt");

    try part1(allocator, &lines);
    lines.reset();
}

pub fn part1(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !void {
    var points: std.ArrayList(Point) = .empty;
    while (lines.next()) |line| {
        if (line.len < 40) continue;
        const px = try std.fmt.parseInt(i64, std.mem.trim(u8, line[11..16], " "), 10);
        const py = try std.fmt.parseInt(i64, std.mem.trim(u8, line[17..24], " "), 10);
        const vx = try std.fmt.parseInt(i64, std.mem.trim(u8, line[36..38], " "), 10);
        const vy = try std.fmt.parseInt(i64, std.mem.trim(u8, line[39..42], " "), 10);

        try points.append(allocator, Point{
            .x = px,
            .y = py,
            .vx = vx,
            .vy = vy,
        });
    }
    std.debug.print("{d}\n", .{points.items.len});
    var set = try to_map(allocator, points.items);
    var second: usize = 0;
    var all_local: bool = false;
    while (!all_local) : (second += 1) {
        for (points.items) |*point| {
            point.x += point.vx;
            point.y += point.vy;
        }
        set.deinit();
        set = try to_map(allocator, points.items);
        all_local = every_point_is_local(set);
    }
    std.debug.print("all are local at second {d}", .{second});
}

const Point = struct {
    x: i64,
    y: i64,
    vx: i64,
    vy: i64,
};

const Coord = struct { x: i64, y: i64 };

fn to_map(allocator: std.mem.Allocator, points: []Point) !std.AutoHashMap(Coord, bool) {
    var set = std.AutoHashMap(Coord, bool).init(allocator);
    for (points) |point| {
        const c = Coord{ .x = point.x, .y = point.y };
        try set.put(c, true);
    }
    return set;
}

fn every_point_is_local(set: std.AutoHashMap(Coord, bool)) bool {
    var iter = set.keyIterator();
    var hold_c = Coord{ .x = 0, .y = 0 };
    outer: while (iter.next()) |c| {
        for (0..2) |i| {
            for (0..2) |j| {
                var true_i: i64 = @intCast(i);
                true_i -= 1;
                var true_j: i64 = @intCast(j);
                true_j -= 1;
                hold_c.x = c.x + true_i;
                hold_c.y = c.y + true_j;
                if (true_i - 1 == 0 and true_j - 1 == 0) continue;
                if (set.get(hold_c)) |_| continue :outer;
            }
        }
        return false;
    }
    return true;
}

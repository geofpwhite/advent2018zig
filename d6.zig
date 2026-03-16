const std = @import("std");
const parse = @import("util.zig").parse;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d6/input.txt");
    // var lines = try parse(allocator, "d6/test.txt");
    try part1(allocator, &lines);
}

pub fn part1(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !void {
    var coord_ary: std.ArrayList(coords) = .empty;
    //parse coordary and get max/min x/y values
    var min_x: i64 = std.math.maxInt(i64);
    var max_x: i64 = 0;
    var min_y: i64 = std.math.maxInt(i64);
    var max_y: i64 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var comma: usize = 0;
        while (line[comma] != ',') {
            comma += 1;
        }
        const x = try std.fmt.parseInt(i64, line[0..comma], 10);
        var len = line.len;
        if (line[line.len - 1] == '\r') {
            len -= 1;
        }
        const y = try std.fmt.parseInt(i64, line[comma + 2 .. len], 10);
        min_x = @min(x, min_x);
        min_y = @min(y, min_y);
        max_x = @max(x, max_x);
        max_y = @max(y, max_y);
        try coord_ary.append(allocator, coords{ .x = x, .y = y });
    }

    // check perimeter of big rectangle around the field to see which (probably but I think definitely) coords have infinite area
    var perimeter_coord: coords = coords{ .x = min_x - 100, .y = min_y - 100 };
    var infinite = std.AutoHashMap(coords, bool).init(allocator);
    var i: i64 = min_x - 100;
    while (i < max_x + 100) : (i += 1) {
        // std.debug.print("{any}", .{perimeter_coord});
        perimeter_coord.x = i;
        if (closest(perimeter_coord, coord_ary.items)) |cl| {
            try infinite.put(cl, true);
        }
    }
    i = min_y - 100;
    while (i < max_y + 100) : (i += 1) {
        // std.debug.print("{any}", .{perimeter_coord});
        perimeter_coord.y = i;
        if (closest(perimeter_coord, coord_ary.items)) |cl| {
            try infinite.put(cl, true);
        }
    }
    i = min_x - 100;
    while (i < max_x + 100) : (i += 1) {
        // std.debug.print("{any}", .{perimeter_coord});
        perimeter_coord.x = i;
        if (closest(perimeter_coord, coord_ary.items)) |cl| {
            try infinite.put(cl, true);
        }
    }
    i = min_y - 100;
    perimeter_coord.x = min_x - 100;
    while (i < max_y + 100) : (i += 1) {
        // std.debug.print("{any}", .{perimeter_coord});
        perimeter_coord.y = i;
        if (closest(perimeter_coord, coord_ary.items)) |cl| {
            try infinite.put(cl, true);
        }
    }
    var highest_area: usize = 0;
    for (coord_ary.items) |coord| {
        const inf = infinite.get(coord);
        if (inf == null) {
            const check_area = try area(allocator, coord, coord_ary.items);
            highest_area = @max(highest_area, check_area);
        }
    }
    std.debug.print("{d}\n", .{highest_area});
}

const coords = struct {
    x: i64,
    y: i64,

    pub fn eql(self: coords, other: coords) bool {
        return self.x == other.x and self.y == other.y;
    }
};

pub fn all_true(to_check: [4]bool) bool {
    return to_check[0] and to_check[1] and to_check[2] and to_check[3];
}

pub fn manhattan(coord1: coords, coord2: coords) usize {
    return @intCast(@abs(coord1.x - coord2.x) + @abs(coord1.y - coord2.y));
}

pub fn closest(check_coord: coords, ary: []coords) ?coords {
    var closest_coord = ary[0];
    var closest_distance = manhattan(check_coord, ary[0]);
    var multiple_closest = false;
    for (ary[1..]) |c| {
        if (c.eql(check_coord)) return c;
        const mh = manhattan(check_coord, c);
        if (mh == closest_distance) multiple_closest = true;
        if (mh < closest_distance) {
            closest_coord = c;
            closest_distance = mh;
            multiple_closest = false;
        }
    }
    if (multiple_closest) {
        // std.debug.print("distance between {any} and {any} is {d} but there's multiple\n", .{ check_coord, closest_coord, closest_distance });
        return null;
    }
    // std.debug.print("distance between {any} and {any} is {d} and that's the closest\n", .{ check_coord, closest_coord, closest_distance });
    return closest_coord;
}

pub fn area(allocator: std.mem.Allocator, coord: coords, ary: []coords) !usize {
    var visited = std.AutoHashMap(coords, bool).init(allocator);
    var buffer: [10000]coords = std.mem.zeroes([10000]coords);
    var queue = try DequeArray(coords).init(&buffer);
    try queue.enqueue(coord);
    var cur_area: usize = 0;
    while (queue.dequeue()) |c| {
        // std.debug.print("length queue = {d}\n", .{queue.len()});
        const up = coords{ .x = c.x, .y = c.y - 1 };
        const down = coords{ .x = c.x, .y = c.y + 1 };
        const left = coords{ .x = c.x - 1, .y = c.y };
        const right = coords{ .x = c.x + 1, .y = c.y };
        const closest_coord = closest(c, ary);
        if (visited.get(c)) |_| continue;
        try visited.put(c, true);
        if (closest_coord) |cl| if (cl.eql(coord)) {
            cur_area += 1;
            const vu = visited.get(up);
            const vd = visited.get(down);
            const vl = visited.get(left);
            const vr = visited.get(right);

            if (null == vu or !vu.?) {
                try queue.enqueue(up);
            }
            if (null == vd or !vd.?) {
                try queue.enqueue(down);
            }
            if (null == vl or !vl.?) {
                try queue.enqueue(left);
            }
            if (null == vr or !vr.?) {
                try queue.enqueue(right);
            }
        };
    }
    return cur_area;
}

const DequeueError = error{Full};
pub fn DequeArray(comptime T: type) type {
    return struct {
        buffer: []T,
        first: usize,
        last: usize,
        empty: bool,
        pub fn init(buffer: []T) !@This() {
            return .{
                .buffer = buffer,
                .first = 0,
                .last = 0,
                .empty = true,
            };
        }

        pub fn enqueue(self: *@This(), item: T) !void {
            if (self.last == self.first and !self.empty) return DequeueError.Full;
            self.buffer[self.last] = item;
            self.last = (self.last + 1) % self.buffer.len;
            self.empty = false;
        }

        pub fn dequeue(self: *@This()) ?T {
            if (self.empty) {
                return null;
            }
            if (self.last == self.first + 1) self.empty = true;
            const return_value = self.buffer[self.first];
            self.first = (self.first + 1) % self.buffer.len;
            return return_value;
        }

        pub fn len(self: *@This()) usize {
            if (self.last == self.first and !self.empty) {
                return self.buffer.len;
            }
            if (self.last < self.first) {
                return self.buffer.len - (self.first - self.last);
            }
            return self.last - self.first;
        }
    };
}

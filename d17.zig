const std = @import("std");
const parse = @import("./util.zig").parse;

fn write_out(allocator: std.mem.Allocator, min_y: usize, max_y: usize, max_x: usize, field: std.AutoHashMap(Coord, void), water: std.AutoHashMap(Coord, void)) !void {
    var f = try std.fs.cwd().createFile("d17/output.txt", .{});
    // const input = std.fs.cwd().readFile(path, input_buffer) catch |err| {
    //     std.debug.print("Failed to read input file: {}\n", .{err});
    //     return err;
    for (min_y..max_y) |y| {
        var line: std.ArrayList(u8) = .empty;
        for (400..max_x) |x| {
            if (field.get(.{ .x = x, .y = y })) |_| {
                try line.append(allocator, '#');
            } else if (water.get(.{ .x = x, .y = y })) |_| {
                try line.append(allocator, '+');
            } else {
                try line.append(allocator, '.');
            }
        }
        _ = try f.write(line.items);
        _ = try f.write("\n");
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var min_y: usize, var max_y: usize = .{ std.math.maxInt(usize), 0 };
    var max_x: usize = 0;
    var lines = try parse(allocator, "d17/input.txt");
    var water: std.AutoHashMap(Coord, void) = .init(allocator);
    var field: std.AutoHashMap(Coord, void) = .init(allocator);
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var spliter = std.mem.splitAny(u8, line, ",");
        switch (line[0]) {
            'x' => {
                var x_str = spliter.next().?;
                x_str = x_str[2..];
                const x = try std.fmt.parseInt(usize, std.mem.trim(u8, x_str, "\n\r=[] "), 10);
                std.debug.print("{s}\n", .{line});
                var y_str = spliter.next().?;
                std.debug.print("{s}\n", .{y_str});
                y_str = y_str[2..];
                const index = std.mem.indexOf(u8, y_str, "..").?;
                const y1_str, const y2_str = .{ y_str[0..index], y_str[index + 2 ..] };
                const y1 = try std.fmt.parseInt(usize, std.mem.trim(u8, y1_str, "\n\r=[] "), 10);
                const y2 = try std.fmt.parseInt(usize, std.mem.trim(u8, y2_str, "\n\r=[] "), 10);
                if (y1 < min_y) min_y = y1;
                if (y2 > max_y) max_y = y2;
                if (x > max_x) max_x = x;
                for (y1..y2 + 1) |y| {
                    try field.put(.{ .x = x, .y = y }, {});
                }
            },
            'y' => {
                var y_str = spliter.next().?;
                y_str = y_str[2..];
                const y = try std.fmt.parseInt(usize, std.mem.trim(u8, y_str, "\n\r=[] "), 10);
                var x_str = spliter.next().?;
                x_str = x_str[2..];
                const index = std.mem.indexOf(u8, x_str, "..").?;
                const x1_str, const x2_str = .{ x_str[0..index], x_str[index + 2 ..] };
                const x1 = try std.fmt.parseInt(usize, std.mem.trim(u8, x1_str, "\n\r=[] "), 10);
                const x2 = try std.fmt.parseInt(usize, std.mem.trim(u8, x2_str, "\n\r=[] "), 10);
                if (y < min_y) min_y = y;
                if (y > max_y) max_y = y;
                if (x2 > max_x) max_x = x2;
                for (x1..x2 + 1) |x| {
                    try field.put(.{ .x = x, .y = y }, {});
                }
            },
            else => unreachable,
        }
    }
    try write_out(allocator, min_y, max_y, max_x, field, water);
    try water.put(.{ .x = 500, .y = 0 }, {});
    try water.put(.{ .x = 500, .y = 1 }, {});
    try water.put(.{ .x = 500, .y = 2 }, {});
    var c: Coord = .{ .x = 500, .y = 3 };
    std.debug.print("{any}\n", .{check_valid(&water, &field, &c)});
    var num: usize = 1;
    std.debug.print("{d} max_x\n", .{max_x});
    var water_heap: std.PriorityQueue(Coord, void, cmp_below) = .init(allocator, {});
    var w_iter = water.keyIterator();
    while (w_iter.next()) |w| {
        try water_heap.add(w.*);
    }
    while (!try next_droplet_iter(allocator, min_y, max_y, max_x, &water, &field)) {
        std.debug.print("{d}\n", .{num});
        num += 1;
    }

    try write_out(allocator, min_y, max_y, max_x, field, water);
}
fn cmp_below(_: void, a: Coord, b: Coord) std.math.Order {
    return std.math.order(a.y, b.y);
}

fn next_droplet_heap(allocator: std.mem.Allocator, min_y: usize, max_y: usize, max_x: usize, water: *std.PriorityQueue(Coord, void, cmp_below), field: *std.AutoHashMap(Coord, void), real_water: *std.AutoHashMap(
    Coord,
    void,
)) !bool {
    var popped: std.ArrayList(Coord) = .empty;
    var valid_found: ?Coord = null;
    var wtr = water.*;
    while (valid_found == null) {
        var p = wtr.remove();
        if (p.y >= max_y) break;
        try popped.append(allocator, p);
        const lra = p.left_right_above();
        // std.debug.print("lra {any}\n", .{lra});
        if (lra.left) |l| if (field.get(l) == null and real_water.get(l) == null and l.x < max_x and l.y > min_y and l.y < max_y) {
            // try valid_coords.append(allocator, l);
            if (valid_found) |cv| {
                if (cv.y < l.y) valid_found = l;
            } else {
                valid_found = l;
            }
        };
        if (lra.right) |r| if (field.get(r) == null and real_water.get(r) == null and r.x < max_x and r.y > min_y and r.y < max_y) {
            // try valid_coords.append(allocator, r);
            // if (valid_found.y < r.y) cur_valid = r;
            if (valid_found) |cv| {
                if (cv.y < r.y) valid_found = r;
            } else {
                valid_found = r;
            }
        };
        const below = Coord{ .x = p.x, .y = p.y + 1 };
        // std.debug.print("maxx {d} miny {d} maxy {d} \n", .{ max_x, min_y, max_y });
        // std.debug.print("lrab {any} {any}\n", .{ lra, below });
        // std.debug.print("{any} {any} {any} {any} {any}\n", .{ field.get(below) == null, real_water.get(below) == null, below.x < max_x, below.y > min_y, below.y < max_y });
        if (field.get(below) == null and real_water.get(below) == null and below.x < max_x and below.y >= min_y and below.y < max_y) {
            // std.debug.print("again {any} {any}\n", .{ lra, below });
            // std.debug.print("{any} {any} {any} {any} {any}\n", .{ field.get(below) == null, real_water.get(below) == null, below.x < max_x, below.y > min_y, below.y < max_y });
            // try valid_coords.append(allocator, .{ .x = w.x, .y = w.y + 1 });
            // if (valid_found.y < below.y) cur_valid = below;
            valid_found = below;
            break;
        }
    }
    for (popped.items) |po| {
        try water.add(po);
        try real_water.put(po, {});
    }
    if (valid_found) |vf| {
        try water.add(vf);
        try real_water.put(vf, {});
        return false;
    }
    return true;
}

fn next_droplet_iter(_: std.mem.Allocator, min_y: usize, max_y: usize, max_x: usize, water: *std.AutoHashMap(Coord, void), field: *std.AutoHashMap(Coord, void)) !bool {
    // var valid_coords: std.ArrayList(Coord) = .empty;
    var cur_valid: ?Coord = null;
    var water_iter = water.keyIterator();
    while (water_iter.next()) |w| {
        // std.debug.print("water droplet at {any}\n", .{w});

        const lra = w.left_right_above();
        // std.debug.print("lra {any}\n", .{lra});
        if (lra.left) |l| if (field.get(l) == null and water.get(l) == null and l.x < max_x and l.y > min_y and l.y < max_y) {
            // try valid_coords.append(allocator, l);
            if (cur_valid) |cv| {
                if (cv.y < l.y) cur_valid = l;
            } else {
                cur_valid = l;
            }
        };
        if (lra.right) |r| if (field.get(r) == null and water.get(r) == null and r.x < max_x and r.y > min_y and r.y < max_y) {
            // try valid_coords.append(allocator, r);
            // if (cur_valid.y < r.y) cur_valid = r;
            if (cur_valid) |cv| {
                if (cv.y < r.y) cur_valid = r;
            } else {
                cur_valid = r;
            }
        };
        const below = Coord{ .x = w.x, .y = w.y + 1 };
        // std.debug.print("maxx {d} miny {d} maxy {d} \n", .{ max_x, min_y, max_y });
        // std.debug.print("lrab {any} {any}\n", .{ lra, below });
        // std.debug.print("{any} {any} {any} {any} {any}\n", .{ field.get(below) == null, water.get(below) == null, below.x < max_x, below.y > min_y, below.y < max_y });
        if (field.get(below) == null and water.get(below) == null and below.x < max_x and below.y >= min_y and below.y < max_y) {
            // std.debug.print("{any} {any} {any} {any} {any}\n", .{ field.get(below) == null, water.get(below) == null, below.x < max_x, below.y > min_y, below.y < max_y });
            // try valid_coords.append(allocator, .{ .x = w.x, .y = w.y + 1 });
            if (max_y <= below.y) cur_valid = below;
            if (cur_valid) |cv| {
                if (cv.y < below.y) cur_valid = below;
            } else {
                cur_valid = below;
            }
        }
    }
    // std.sort.insertion(Coord, valid_coords.items, {}, cmp_lower);

    if (cur_valid == null) return true;
    std.debug.print("{any}\n", .{cur_valid});
    try water.put(cur_valid.?, {});
    return false;
}
//true if water flows out of our assigned area
fn next_droplet(allocator: std.mem.Allocator, min_y: usize, max_y: usize, max_x: usize, water: *std.AutoHashMap(Coord, void), field: *std.AutoHashMap(Coord, void)) !bool {
    var valid_coords: std.ArrayList(Coord) = .empty;
    for (300..max_x) |x| {
        for (min_y..max_y + 2) |y| {
            var coord = Coord{ .x = x, .y = y };
            if (check_valid(water, field, &coord)) {
                try valid_coords.append(allocator, coord);
            }
        }
    }
    std.sort.insertion(Coord, valid_coords.items, {}, cmp_lower);

    if (valid_coords.items.len == 0 or valid_coords.items[0].y > max_y - 1) return true;
    try water.put(valid_coords.items[0], {});
    return false;
}
pub fn cmp_lower(_: void, c1: Coord, c2: Coord) bool {
    if (c1.y != c2.y) return c1.y > c2.y;
    return false;
}
fn check_valid(water: *std.AutoHashMap(Coord, void), field: *std.AutoHashMap(Coord, void), coord: *Coord) bool {
    if (field.get(coord.*) != null or water.get(coord.*) != null) return false;
    const neighbors = coord.left_right_above();
    if (neighbors.left) |l| if (water.get(l)) |_| {
        return true;
    };
    if (neighbors.right) |r| if (water.get(r)) |_| {
        return true;
    };
    if (neighbors.above) |u| if (water.get(u)) |_| {
        return true;
    };
    return false;
}

const Coord = struct {
    x: usize,
    y: usize,

    fn left_right_above(self: *Coord) struct { left: ?Coord, right: ?Coord, above: ?Coord } {
        const left = if (self.x > 0) Coord{ .x = self.x - 1, .y = self.y } else null;
        const right = Coord{ .x = self.x + 1, .y = self.y };
        const above = if (self.y > 0) Coord{ .x = self.x, .y = self.y - 1 } else null;
        return .{ .left = left, .right = right, .above = above };
    }
};

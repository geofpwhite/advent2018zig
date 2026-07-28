const std = @import("std");
const parse = @import("./util.zig").parse;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // var lines = try parse(allocator, "d15/input.txt");
    // var lines = try parse(allocator, "d15/test.txt");
    // var lines = try parse(allocator, "d15/test2.txt");
    var lines = try parse(allocator, "d15/test2.txt");
    var goblins = std.AutoHashMap(unit, usize).init(allocator);
    var elves = std.AutoHashMap(unit, usize).init(allocator);
    var field = std.AutoHashMap(unit, void).init(allocator);
    var elf_total: usize = 0;
    var goblin_total: usize = 0;
    var y: usize = 0;
    while (lines.next()) |line| {
        std.debug.print("{s}\n", .{line});
        for (line, 0..line.len) |char, x| {
            switch (char) {
                '.' => try field.put(unit{
                    .x = x,
                    .y = y,
                }, {}),
                'E' => {
                    try field.put(unit{
                        .x = x,
                        .y = y,
                    }, {});
                    try elves.put(unit{
                        .x = x,
                        .y = y,
                    }, 200);
                    elf_total += 1;
                },
                'G' => {
                    try field.put(unit{
                        .x = x,
                        .y = y,
                    }, {});
                    try goblins.put(unit{
                        .x = x,
                        .y = y,
                    }, 200);
                    goblin_total += 1;
                },
                else => continue,
            }
        }
        y += 1;
    }
    // var elves_copy = try elves.clone();
    // var goblins_copy = try goblins.clone();
    // var elf_total_copy = elf_total;
    // var goblin_total_copy = goblin_total;
    _ = try part1(allocator, field, &elves, &goblins, &elf_total, &goblin_total, 16);
    // try part2(allocator, field, &elves_copy, &goblins_copy, &elf_total_copy, &goblin_total_copy);
    lines.reset();
}
fn part2(allocator: std.mem.Allocator, field: std.AutoHashMap(unit, void), elves_ptr: *std.AutoHashMap(unit, usize), goblins_ptr: *std.AutoHashMap(unit, usize), elf_total_ptr: *usize, goblin_total_ptr: *usize) !void {
    var cur: usize = 30;
    var elves_copy = try elves_ptr.*.clone();
    var goblins_copy = try goblins_ptr.*.clone();
    var elf_total_copy = elf_total_ptr.*;
    var goblin_total_copy = goblin_total_ptr.*;
    var check = try part1(allocator, field, &elves_copy, &goblins_copy, &elf_total_copy, &goblin_total_copy, cur);
    std.debug.print("cur is {d} \n", .{cur});
    while (check.elf_total != elf_total_ptr.*) {
        cur += 1;
        elves_copy = try elves_ptr.*.clone();
        goblins_copy = try goblins_ptr.*.clone();
        elf_total_copy = elf_total_ptr.*;
        goblin_total_copy = goblin_total_ptr.*;
        check = try part1(allocator, field, &elves_copy, &goblins_copy, &elf_total_copy, &goblin_total_copy, cur);
        std.debug.print("cur is {d} \n", .{cur});
    }
}

fn part1(allocator: std.mem.Allocator, field: std.AutoHashMap(unit, void), elves_ptr: *std.AutoHashMap(unit, usize), goblins_ptr: *std.AutoHashMap(unit, usize), elf_total_ptr: *usize, goblin_total_ptr: *usize, elf_attack_power: usize) !struct { elf_total: usize, elf_total_health: usize } {
    var rounds: usize = 0;
    var elves = elves_ptr.*;
    var goblins = goblins_ptr.*;
    var elf_total = elf_total_ptr.*;
    var goblin_total = goblin_total_ptr.*;
    // const starting_total_elf, const starting_total_goblin = .{ elf_total, goblin_total };
    // try print(elves_ptr, goblins_ptr, &elf_total, &goblin_total, rounds);
    while (elf_total > 0 and goblin_total > 0) {
        // try print(elves_ptr, goblins_ptr, &elf_total, &goblin_total, rounds);
        // try print_field(allocator, field, elves_ptr, goblins_ptr);
        // if (rounds > 2) break;
        // std.debug.print("{d} {d}\n", .{ elf_total, goblin_total });
        var pq: std.PriorityQueue(unit, void, u_cmp) = .init(allocator, {});
        defer pq.deinit();
        var e_iter = elves.keyIterator();
        var g_iter = goblins.keyIterator();
        while (e_iter.next()) |u| {
            try pq.add(u.*);
        }
        while (g_iter.next()) |u| {
            try pq.add(u.*);
        }
        while (pq.items.len > 0) {
            var u = pq.remove();
            // std.debug.print("{any}\n", .{pq.items});
            // std.debug.print("{d} {d} u\n", .{ u.x, u.y });
            if (elves.get(u)) |hp| {
                // std.debug.print("{d} hp of elf at {d} {d} \n", .{ hp, u.x, u.y });
                g_iter = goblins.keyIterator();
                var shortest = path_val{ .steps = std.math.maxInt(usize), .path = u };
                _ = elves.remove(u);
                const nu = try best_move(allocator, u, .e, field, elves, goblins);
                shortest.path = nu;
                // std.debug.print("{d} {d} shortest\n", .{ shortest.path.x, shortest.path.y });
                // if (!u.eql(shortest.path))
                //     std.debug.print("{any} shortest\n", .{u});
                // if (elves.get(.{ .x = shortest.path.x, .y = shortest.path.y })) |_| {
                //     try elves.put(u, hp);
                //     continue;
                // }
                // if (goblins.get(.{ .x = shortest.path.x, .y = shortest.path.y })) |_| {
                //     shortest.path.x = u.x;
                //     shortest.path.y = u.y;
                // }
                var units_in_range = try in_range(allocator, .e, u, elves, goblins);
                // std.debug.print("{any} uir\n", .{units_in_range});

                // std.debug.print("elf {d} {d} moving to ", .{ u.x, u.y });
                if (units_in_range.units.len == 0) {
                    u.x = shortest.path.x;
                    u.y = shortest.path.y;
                    units_in_range = try in_range(allocator, .e, u, elves, goblins);
                }
                // std.debug.print("{d} {d}\n", .{ u.x, u.y });
                try elves.put(u, hp);
                // std.debug.print("{any} uir\n", .{units_in_range});
                if (units_in_range.units.len == 0) continue;
                var lowest_index: usize = 0;
                for (units_in_range.hps, 0..units_in_range.hps.len) |hP, i| {
                    if (units_in_range.units[i].eql(u)) continue;
                    if (hP < units_in_range.hps[lowest_index]) lowest_index = i;
                }
                const new_unit = units_in_range.units[lowest_index];
                const newHP = units_in_range.hps[lowest_index];
                _ = goblins.remove(new_unit);
                if (newHP > elf_attack_power) {
                    // std.debug.print("elf attacking {any}\n", .{new_unit});
                    try goblins.put(new_unit, newHP - elf_attack_power);
                } else goblin_total -= 1;
            } else if (goblins.get(u)) |hp| {
                // std.debug.print("{d} hp \n", .{hp});
                // std.debug.print("{d} hp of goblin at {d} {d} \n", .{ hp, u.x, u.y });
                e_iter = elves.keyIterator();
                var shortest = path_val{ .steps = std.math.maxInt(usize), .path = u };
                _ = goblins.remove(u);
                const nu = try best_move(allocator, u, .g, field, elves, goblins);
                shortest.path = nu;
                // if (!u.eql(shortest.path))
                // if (goblins.get(.{ .x = shortest.path.x, .y = shortest.path.y })) |_| {
                //     try goblins.put(u, hp);
                //     continue;
                // }
                // if (elves.get(.{ .x = shortest.path.x, .y = shortest.path.y })) |_| {
                //     try goblins.put(u, hp);
                //     continue;
                // }
                var units_in_range = try in_range(allocator, .g, u, elves, goblins);
                // std.debug.print("goblin {d} {d} moving to ", .{ u.x, u.y });
                if (units_in_range.units.len == 0) {
                    u.x = shortest.path.x;
                    u.y = shortest.path.y;
                    units_in_range = try in_range(allocator, .g, u, elves, goblins);
                }
                // std.debug.print("{d} {d}\n", .{ u.x, u.y });
                try goblins.put(u, hp);
                if (units_in_range.units.len == 0) continue;
                var lowest_index: usize = 0;
                // std.debug.print("{any} uir\n", .{units_in_range});
                for (units_in_range.hps, 0..units_in_range.hps.len) |hP, i| {
                    // std.debug.print("{d} {d} {d} range hp\n", .{ units_in_range.units[i].x, units_in_range.units[i].y, hP });
                    if (hP < units_in_range.hps[lowest_index]) lowest_index = i;
                }
                const new_unit = units_in_range.units[lowest_index];
                const newHP = units_in_range.hps[lowest_index];
                // std.debug.print("{d} range hp\n", .{newHP - 3});
                _ = elves.remove(new_unit);
                if (newHP > 3) {
                    // std.debug.print("{d} range hp\n", .{newHP - 3});
                    // std.debug.print("goblin attacking {any}\n", .{new_unit});
                    try elves.put(new_unit, newHP - 3);
                } else elf_total -= 1;
            }
        }
        rounds += 1;
        std.debug.print("round: {d} gt: {d} et: {d}\n", .{ rounds, goblin_total, elf_total });
    }
    try print(elves_ptr, goblins_ptr, &elf_total, &goblin_total, rounds);
    var gsum: usize = 0;
    var esum: usize = 0;
    var giter = goblins.valueIterator();
    var eiter = elves.valueIterator();
    while (giter.next()) |num| {
        gsum += num.*;
    }
    while (eiter.next()) |num| {
        esum += num.*;
    }
    std.debug.print("goblin total health: {d}, elf total health: {d} \n", .{ gsum, esum });
    try print_field(allocator, field, elves_ptr, goblins_ptr);
    return .{ .elf_total = elf_total, .elf_total_health = esum };
}
fn print(elves_ptr: *std.AutoHashMap(unit, usize), goblins_ptr: *std.AutoHashMap(unit, usize), elf_total_ptr: *usize, goblin_total_ptr: *usize, rounds: usize) !void {
    var elves, var goblins = .{ elves_ptr.*, goblins_ptr.* };
    var ge = goblins.keyIterator();
    var ee = elves.keyIterator();
    // std.debug.print("\033[31mgoblins: {d}\n  ", .{goblin_total_ptr.*});
    const red = "\x1b[31m";
    const green = "\x1b[32m";
    const blue = "\x1b[34m";
    const reset = "\x1b[0m";

    std.debug.print("{s} goblins: {d}\n  ", .{ green, goblin_total_ptr.* });

    while (ge.next()) |coord| {
        std.debug.print("({d},{d}): ", .{ coord.x, coord.y });
        const hp = goblins.get(coord.*);
        if (hp) |hP| std.debug.print("{d} ,", .{hP});
    }
    std.debug.print("\n", .{});
    std.debug.print("{s} elves: {d}\n  ", .{ blue, elf_total_ptr.* });
    while (ee.next()) |coord| {
        std.debug.print("({d},{d}): ", .{ coord.x, coord.y });
        const hp = elves.get(coord.*);
        if (hp) |hP| std.debug.print("{d}, ", .{hP});
    }
    std.debug.print("{s}", .{reset});
    std.debug.print("\n", .{});
    std.debug.print("{s} rounds: {d}\n", .{ red, rounds });
    std.debug.print("{s}", .{reset});
}
fn print_field(allocator: std.mem.Allocator, field: std.AutoHashMap(unit, void), elves_ptr: *std.AutoHashMap(unit, usize), goblins_ptr: *std.AutoHashMap(unit, usize)) !void {
    var f_iter = field.keyIterator();
    var h: usize, var w: usize = .{ 0, 0 };
    while (f_iter.next()) |u| {
        // std.debug.print("{any}\n", .{u});
        w = @max(u.x, w);
        h = @max(u.y, h);
    }
    var elves, var goblins = .{ elves_ptr.*, goblins_ptr.* };
    var buffer: []u8 = try allocator.alloc(u8, w + 4);
    buffer[w + 3] = '\n';
    std.debug.print("{d},{d}\n", .{ w + 3, h + 3 });
    for (0..h + 3) |y| {
        for (0..w + 3) |x| {
            if (elves.get(.{ .x = x, .y = y })) |_| {
                buffer[x] = 'E';
                continue;
            }
            if (goblins.get(.{ .x = x, .y = y })) |_| {
                buffer[x] = 'G';
                continue;
            }
            if (field.get(.{ .x = x, .y = y })) |_| {
                buffer[x] = '.';
                continue;
            }
            buffer[x] = '#';
        }
        std.debug.print("{s}", .{buffer});
    }
}

const unit = struct {
    x: usize,
    y: usize,
    fn eql(self: unit, other: unit) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const path_val = struct {
    steps: usize,
    path: unit,
};

const unit_type = enum { e, g };

fn in_range(allocator: std.mem.Allocator, team: unit_type, start: unit, elves: std.AutoHashMap(unit, usize), goblins: std.AutoHashMap(unit, usize)) !struct { units: []unit, hps: []usize } {
    var units: std.ArrayList(unit) = .empty;
    var hps: std.ArrayList(usize) = .empty;
    for (0..3) |i| for (0..3) |j| {
        if ((i == 1 and j == 1) or (i != 1 and j != 1)) continue;
        const u = unit{ .x = start.x - 1 + i, .y = start.y - 1 + j };
        // std.debug.print("in range check {any} {any}\n", .{ start, u });
        switch (team) {
            .e => {
                if (goblins.get(u)) |hp| {
                    try units.append(allocator, u);
                    try hps.append(allocator, hp);
                }
            },
            .g => {
                if (elves.get(u)) |hp| {
                    try units.append(allocator, u);
                    try hps.append(allocator, hp);
                }
            },
        }
    };
    return .{ .units = units.items, .hps = hps.items };
}
fn best_move(allocator: std.mem.Allocator, start: unit, utype: unit_type, field: std.AutoHashMap(unit, void), elves: std.AutoHashMap(unit, usize), goblins: std.AutoHashMap(unit, usize)) !unit {
    const cl = try closest(allocator, start, utype, field, elves, goblins);
    if (cl == 1) return start;
    var closer: std.ArrayList(unit) = .empty;
    for ([_]usize{ 0, 2 }) |i| {
        const ux = unit{ .x = start.x + i - 1, .y = start.y };
        const uy = unit{ .x = start.x, .y = start.y + i - 1 };
        if (is_empty(ux, field, elves, goblins)) {
            const clx = try closest(allocator, ux, utype, field, elves, goblins);
            if (clx < cl) try closer.append(allocator, ux);
        }
        if (is_empty(uy, field, elves, goblins)) {
            const cly = try closest(allocator, uy, utype, field, elves, goblins);
            if (cly < cl) try closer.append(allocator, uy);
        }
    }
    std.sort.insertion(unit, closer.items, {}, u_cmp_insert);
    // std.debug.print("{d} closest\n", .{cl});
    // std.debug.print("{any} start\n", .{start});
    if (closer.items.len == 0) return start;
    return closer.items[0];
}
fn is_empty(check: unit, field: std.AutoHashMap(unit, void), elves: std.AutoHashMap(unit, usize), goblins: std.AutoHashMap(unit, usize)) bool {
    const cf = field.get(check);
    const ce = elves.get(check);
    const cg = goblins.get(check);
    return cf != null and ce == null and cg == null;
}
fn closest(allocator: std.mem.Allocator, start: unit, utype: unit_type, field: std.AutoHashMap(unit, void), elves: std.AutoHashMap(unit, usize), goblins: std.AutoHashMap(unit, usize)) !usize {
    var closest_num: usize = std.math.maxInt(usize);
    switch (utype) {
        .e => {
            var g_iter = goblins.keyIterator();
            while (g_iter.next()) |g| {
                const pm = try path(allocator, start, g.*, field, elves, goblins);
                if (pm) |p|
                    if (p.steps < closest_num) {
                        closest_num = p.steps;
                    };
            }
        },
        .g => {
            var e_iter = elves.keyIterator();
            while (e_iter.next()) |e| {
                const pm = try path(allocator, start, e.*, field, elves, goblins);
                if (pm) |p|
                    if (p.steps < closest_num) {
                        closest_num = p.steps;
                    };
            }
        },
    }
    return closest_num;
}

fn path(allocator: std.mem.Allocator, start: unit, end: unit, field: std.AutoHashMap(unit, void), elves: std.AutoHashMap(unit, usize), goblins: std.AutoHashMap(unit, usize)) !?path_val {
    var queue: std.PriorityQueue(queue_node, void, q_cmp) = .init(allocator, {});
    var visited: std.AutoHashMap(unit, void) = .init(allocator);
    var parent: std.AutoHashMap(unit, unit) = .init(allocator);
    defer queue.deinit();
    defer visited.deinit();
    defer parent.deinit();

    try queue.add(.{
        .unit = start,
        .steps = 0,
        .prev = null,
    });

    try visited.put(start, {});
    var end_found: ?unit = null;
    var end_steps: usize = 0;

    outer: while (queue.items.len > 0) {
        var cur = queue.remove();

        if (cur.unit.eql(end)) {
            end_found = cur.unit;
            end_steps = cur.steps;
            break;
        }

        if (elves.get(cur.unit) != null or goblins.get(cur.unit) != null) continue;

        for (0..3) |j| {
            for (0..3) |i| {
                if ((cur.unit.x == 0 and i == 0) or (cur.unit.y == 0 and j == 0) or (i == 1 and j == 1) or (i != 1 and j != 1)) continue;

                // std.debug.print("{d} {d}\n", .{ cur.unit.x, i });
                const u = unit{
                    .x = cur.unit.x + i - 1,
                    .y = cur.unit.y + j - 1,
                };

                if (visited.contains(u)) continue;

                if (u.eql(end)) {
                    // Found the end, record parent and exit
                    try parent.put(u, cur.unit);
                    end_found = u;
                    end_steps = cur.steps + 1;
                    break :outer;
                }

                if (field.get(u)) |_| if ((elves.get(u) == null and goblins.get(u) == null) or u.eql(end)) {
                    try visited.put(u, {});
                    try parent.put(u, cur.unit);
                    try queue.add(.{
                        .unit = u,
                        .steps = cur.steps + 1,
                        .prev = null,
                    });
                };
            }
        }
    }

    if (end_found) |end_unit| {
        // Reconstruct path from end to start by following parent pointers
        var current = end_unit;

        while (parent.get(current)) |p| {
            if (p.eql(start)) {
                // Current is the first move from start
                return .{ .steps = end_steps, .path = current };
            }
            current = p;
        }
    }

    return null;
}

fn q_cmp(_: void, a: queue_node, b: queue_node) std.math.Order {
    return std.math.order(a.steps, b.steps);
}
fn u_cmp(_: void, a: unit, b: unit) std.math.Order {
    if (a.y != b.y) return std.math.order(a.y, b.y);
    return std.math.order(a.x, b.x);
}
fn u_cmp_insert(_: void, a: unit, b: unit) bool {
    if (a.y != b.y) return a.y < b.y;
    return a.x < b.x;
}

const queue_node = struct {
    unit: unit,
    steps: usize,
    prev: ?*queue_node,
};

test "path simple 5x5 empty field" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var field = std.AutoHashMap(unit, void).init(allocator);
    defer field.deinit();

    for (0..5) |y| {
        for (0..5) |x| {
            try field.put(unit{ .x = x, .y = y }, {});
        }
    }

    var elves = std.AutoHashMap(unit, usize).init(allocator);
    defer elves.deinit();

    var goblins = std.AutoHashMap(unit, usize).init(allocator);
    defer goblins.deinit();

    const start = unit{ .x = 1, .y = 1 };
    const end = unit{ .x = 3, .y = 3 };

    const result = try path(allocator, start, end, field, elves, goblins);
    try std.testing.expect(result != null);
    if (result) |r| {
        try std.testing.expect(r.steps == 4);
        try std.testing.expect((r.path.x == 2 and r.path.y == 1) or (r.path.x == 1 and r.path.y == 2));
    }
}

test "path blocked by wall" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var field = std.AutoHashMap(unit, void).init(allocator);
    defer field.deinit();

    for (0..5) |x| {
        if (x != 2) {
            try field.put(unit{ .x = x, .y = 0 }, {});
        }
    }

    var elves = std.AutoHashMap(unit, usize).init(allocator);
    defer elves.deinit();

    var goblins = std.AutoHashMap(unit, usize).init(allocator);
    defer goblins.deinit();

    const start = unit{ .x = 0, .y = 0 };
    const end = unit{ .x = 4, .y = 0 };

    const result = try path(allocator, start, end, field, elves, goblins);
    try std.testing.expect(result == null);
}

test "path around unit" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var field = std.AutoHashMap(unit, void).init(allocator);
    defer field.deinit();

    for (0..3) |y| {
        for (0..3) |x| {
            try field.put(unit{ .x = x, .y = y }, {});
        }
    }

    var elves = std.AutoHashMap(unit, usize).init(allocator);
    defer elves.deinit();
    try elves.put(unit{ .x = 1, .y = 1 }, 200);

    var goblins = std.AutoHashMap(unit, usize).init(allocator);
    defer goblins.deinit();

    const start = unit{ .x = 0, .y = 1 };
    const end = unit{ .x = 2, .y = 1 };

    const result = try path(allocator, start, end, field, elves, goblins);
    try std.testing.expect(result != null);
    if (result) |r| {
        try std.testing.expect((r.path.x == 0 and r.path.y == 0) or (r.path.x == 0 and r.path.y == 2));
    }
}

test "path adjacent to target" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var field = std.AutoHashMap(unit, void).init(allocator);
    defer field.deinit();

    for (0..3) |y| {
        for (0..3) |x| {
            try field.put(unit{ .x = x, .y = y }, {});
        }
    }

    var elves = std.AutoHashMap(unit, usize).init(allocator);
    defer elves.deinit();

    var goblins = std.AutoHashMap(unit, usize).init(allocator);
    defer goblins.deinit();

    const start = unit{ .x = 0, .y = 0 };
    const end = unit{ .x = 1, .y = 0 };

    const result = try path(allocator, start, end, field, elves, goblins);
    try std.testing.expect(result != null);
    if (result) |r| {
        try std.testing.expect(r.steps == 1);
        try std.testing.expect(r.path.x == 1 and r.path.y == 0);
    }
}

test "combat simulation test field" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Mimic the test.txt field:
    // #######
    // #.G.E.#
    // #E.G.E#
    // #.G.E.#
    // #######

    var field = std.AutoHashMap(unit, void).init(allocator);
    defer field.deinit();

    var elves = std.AutoHashMap(unit, usize).init(allocator);
    defer elves.deinit();

    var goblins = std.AutoHashMap(unit, usize).init(allocator);
    defer goblins.deinit();

    // Add walkable spaces (skip walls at boundaries)
    for (0..7) |x| {
        for (0..5) |y| {
            if ((x == 0 or x == 6 or y == 0 or y == 4)) {
                // Walls, skip
            } else {
                try field.put(unit{ .x = x, .y = y }, {});
            }
        }
    }

    // Add units from test.txt
    // Row 1: G at (2,1), E at (4,1)
    try goblins.put(unit{ .x = 2, .y = 1 }, 200);
    try elves.put(unit{ .x = 4, .y = 1 }, 200);

    // Row 2: E at (1,2), G at (3,2), E at (5,2)
    try elves.put(unit{ .x = 1, .y = 2 }, 200);
    try goblins.put(unit{ .x = 3, .y = 2 }, 200);
    try elves.put(unit{ .x = 5, .y = 2 }, 200);

    // Row 3: G at (2,3), E at (4,3)
    try goblins.put(unit{ .x = 2, .y = 3 }, 200);
    try elves.put(unit{ .x = 4, .y = 3 }, 200);

    // Test: Can goblin at (2,1) find a path to nearby elf at (1,2)?
    const goblin_pos = unit{ .x = 2, .y = 1 };
    const nearby_elf = unit{ .x = 1, .y = 2 };

    // Temporarily remove the goblin from the map to allow pathfinding
    _ = goblins.remove(goblin_pos);

    const result = try path(allocator, goblin_pos, nearby_elf, field, elves, goblins);
    try std.testing.expect(result != null);
    std.debug.print("{any}\n", .{result});
    if (result) |r| {
        // First move should be adjacent
        const dx: i32 = @intCast(r.path.x);
        const dy: i32 = @intCast(r.path.y);
        const gx: i32 = @intCast(goblin_pos.x);
        const gy: i32 = @intCast(goblin_pos.y);
        const dist_sq = (dx - gx) * (dx - gx) + (dy - gy) * (dy - gy);
        try std.testing.expect(dist_sq == 1 or dist_sq == 2);
    }
}

const std = @import("std");
const parse = @import("util.zig").parse;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "./d12/input.txt");
    const init_state = lines.next().?[15..];
    var state: [400]bool = std.mem.zeroes([400]bool);
    for (init_state, 0..) |char, i| {
        if (char == '#') state[200 + i] = true;
    }
    var rules: std.AutoHashMap([5]bool, bool) = .init(allocator);
    while (lines.next()) |line| {
        if (line.len < 9) continue;
        var k_buf: [5]bool = [_]bool{ false, false, false, false, false };
        var split_inner = std.mem.splitAny(u8, line, " ");
        const k = split_inner.next().?;
        _ = split_inner.next();
        const v = split_inner.next().?;
        var v_bool = false;
        for (k, 0..) |char, i| {
            switch (char) {
                '#' => k_buf[i] = true,
                else => k_buf[i] = false,
            }
        }
        switch (v[0]) {
            '#' => v_bool = true,
            else => v_bool = false,
        }
        try rules.put(k_buf, v_bool);
    }
    const hold_state = state;
    try part1(allocator, rules, &state);
    state = hold_state;
    try part2(allocator, rules, &state);
    // try part2(rules, &state);
}
fn part2(allocator: std.mem.Allocator, rules: std.AutoHashMap([5]bool, bool), state: *[400]bool) !void {
    var slice_ary: [5]bool = .{ false, false, false, false, false };
    var real_state: [40000]bool = std.mem.zeroes([40000]bool);
    for (200..400) |i| {
        real_state[19800 + i] = state[i];
    }
    var new_state: [40000]bool = std.mem.zeroes([40000]bool);
    for (0..5000) |_| {
        var sum: i64 = 0;
        var first_plant: ?i64 = null;
        var last_plant: i64 = -20000;
        for (2..39997) |i| {
            if (real_state[i]) {
                const i_i64: i64 = @intCast(i);

                sum += i_i64 - 20000;
                if (first_plant == null) {
                    first_plant = i_i64 - 20000;
                }
                last_plant = i_i64 - 20000;
            }
            for (i - 2..i + 3, 0..5) |j, k| {
                slice_ary[k] = real_state[j];
            }
            if (rules.get(slice_ary)) |exists_v| {
                new_state[i] = exists_v;
            }
        }
        real_state = new_state;
        std.debug.print("{d}, {any} to {d}\n", .{ sum, first_plant, last_plant });
        std.debug.print("{s}\n", .{try state_to_string(allocator, &real_state)});
    }
    var sum: i64 = 0;
    var first_plant: ?i64 = null;
    var last_plant: i64 = -20000;
    for (real_state, 0..) |exists, i| if (exists) {
        const i_i64: i64 = @intCast(i);

        sum += i_i64 - 20000 + (50_000_000_000) - 5000;
        if (first_plant == null) {
            first_plant = i_i64 - 20000;
        }
        last_plant = i_i64 - 20000;
    };
    std.debug.print("{d}, {any} to {d}\n", .{ sum, first_plant, last_plant });
}

fn part1(allocator: std.mem.Allocator, rules: std.AutoHashMap([5]bool, bool), state: *[400]bool) !void {
    var slice_ary: [5]bool = [_]bool{ false, false, false, false, false };
    var new_state: [400]bool = std.mem.zeroes([400]bool);
    for (0..20) |_| {
        for (2..397) |i| {
            for (i - 2..i + 3, 0..5) |j, k| {
                slice_ary[k] = state[j];
            }
            if (rules.get(slice_ary)) |exists_v| {
                new_state[i] = exists_v;
            }
        }
        state.* = new_state;
        std.debug.print("{s}\n", .{try state_to_string(allocator, state)});
    }
    var sum: i64 = 0;
    var first_plant: ?i64 = null;
    var last_plant: i64 = -200;
    for (state, 0..) |exists, i| if (exists) {
        const i_i64: i64 = @intCast(i);
        sum += i_i64 - 200;
        if (first_plant == null) {
            first_plant = i_i64 - 200;
        }
        last_plant = i_i64 - 200;
    };
    std.debug.print("{d}, {d} to {d}\n", .{ sum, first_plant.?, last_plant });
}

fn state_to_string(allocator: std.mem.Allocator, state: []bool) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    var begin: usize = 0;
    var end: usize = 0;
    while (begin < state.len and !state[begin]) begin += 1;
    for (begin..state.len) |i| {
        if (state[i]) {
            try buf.append(allocator, '#');
            end = i;
        } else {
            try buf.append(allocator, '.');
        }
    }
    if (begin > end) {
        end = begin;
    }
    return buf.items[0 .. end - begin];
}

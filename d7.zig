const std = @import("std");
const parse = @import("./util.zig").parse;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d7/input.txt");
    try part1(allocator, &lines);
    lines.reset();
    try part2(allocator, &lines);
}

pub fn part2(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !void {
    var nodes: [100]Node = std.mem.zeroes([100]Node);
    while (lines.next()) |line| {
        if (line.len < 37) continue;
        const before = line[5];
        const after = line[36];
        var node_before = nodes[before];
        var node_after = nodes[after];
        var new_before_next: std.ArrayList(u8) = .empty;
        try new_before_next.appendSlice(allocator, node_before.next);
        try new_before_next.append(allocator, after);
        node_before.next = new_before_next.items;
        nodes[before] = node_before;
        var new_after_before: std.ArrayList(u8) = .empty;
        try new_after_before.appendSlice(allocator, node_after.before);
        try new_after_before.append(allocator, before);
        node_after.before = new_after_before.items;
        nodes[after] = node_after;
    }
    var order: [26]u8 = std.mem.zeroes([26]u8);
    var visited: [100]bool = std.mem.zeroes([100]bool);
    var visiting: [100]bool = std.mem.zeroes([100]bool);
    var order_index: usize = 0;
    var workers: [5]u8 = std.mem.zeroes([5]u8);
    var workers_cur_duration: [5]usize = std.mem.zeroes([5]usize);
    var cur_second: usize = 0;
    while (order_index < 26) {
        for (0..5) |i| {
            if (workers[i] == 0) {
                outer: for (nodes[65..91], 65..91) |node, j| {
                    if (visited[j] or visiting[j]) continue;

                    for (node.before) |val| {
                        if (!visited[val]) continue :outer;
                    }
                    // try can_visit.append(allocator,i);
                    workers[i] = @intCast(j);
                    workers_cur_duration[i] = @intCast(j - 4);
                    visiting[j] = true;
                    break;
                }
            }
        }
        var min_worker_duration: usize = std.math.maxInt(usize);
        var min_worker_duration_index: usize = std.math.maxInt(usize);
        for (0..5) |i| {
            if (workers[i] != 0) {
                min_worker_duration = @min(min_worker_duration, workers_cur_duration[i]);
                if (min_worker_duration == workers_cur_duration[i]) min_worker_duration_index = i;
            }
        }
        for (0..5) |i| {
            if (workers_cur_duration[i] > 0) {
                workers_cur_duration[i] -= min_worker_duration;
            }
        }
        cur_second += min_worker_duration;
        order[order_index] = workers[min_worker_duration_index];
        order_index += 1;
        visited[workers[min_worker_duration_index]] = true;
        workers[min_worker_duration_index] = 0;
    }
    // const order_string: []const u8 = &order;
    std.debug.print("{s}\n", .{order});
    std.debug.print("{d}\n", .{cur_second});
}
pub fn part1(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !void {
    var nodes: [100]Node = std.mem.zeroes([100]Node);
    while (lines.next()) |line| {
        if (line.len < 37) continue;
        const before = line[5];
        const after = line[36];
        var node_before = nodes[before];
        var node_after = nodes[after];
        var new_before_next: std.ArrayList(u8) = .empty;
        try new_before_next.appendSlice(allocator, node_before.next);
        try new_before_next.append(allocator, after);
        node_before.next = new_before_next.items;
        nodes[before] = node_before;
        var new_after_before: std.ArrayList(u8) = .empty;
        try new_after_before.appendSlice(allocator, node_after.before);
        try new_after_before.append(allocator, before);
        node_after.before = new_after_before.items;
        nodes[after] = node_after;
    }
    var order: [26]u8 = std.mem.zeroes([26]u8);
    var visited: [100]bool = std.mem.zeroes([100]bool);
    var order_index: usize = 0;
    while (order_index < 26) : (order_index += 1) {
        // var can_visit: std.ArrayList(u8) = .empty;
        outer: for (nodes[65..91], 65..91) |node, i| {
            if (visited[i]) continue;

            for (node.before) |val| {
                if (!visited[val]) continue :outer;
            }
            // try can_visit.append(allocator,i);
            order[order_index] = @intCast(i);
            visited[i] = true;
            break;
        }
    }
    // const order_string: []const u8 = &order;
    std.debug.print("{s}\n", .{order});
}

const Node = struct {
    before: []u8,
    next: []u8,
};

pub fn sort_by_duration(workers: *[5]u8, durations: *[5]usize) !void {
    for (1..5) |i| {
        var j: usize = i;
        while (j > 0 and durations[j] < durations[j - 1]) : (j -= 1) {
            const hold = durations[j - 1];
            const hold_worker = workers[j - 1];
            durations[j - 1] = durations[j];
            workers[j - 1] = workers[j];
            durations[j] = hold;
            workers[j] = hold_worker;
        }
    }
}

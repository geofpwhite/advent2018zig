const std = @import("std");
const parse = @import("util.zig").parse;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // var lines = try parse(allocator, "d4/input.txt");
    var lines = try parse(allocator, "d4/test.txt");
    try part1and2(allocator, &lines);
}

pub fn part1and2(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !void {
    const sorted_lines = try sort_by_date_time(allocator, lines);
    var map = std.AutoArrayHashMap(usize, usize).init(allocator);
    var reverse_map = std.AutoArrayHashMap(usize, usize).init(allocator);
    var ary: [365][60]usize = std.mem.zeroes([365][60]usize);
    var cur_guard_index: usize = 0;
    var cur_guard: usize = 0;
    var cur_fall_asleep_time: usize = 0;
    var cur_start_time: usize = 0;
    for (sorted_lines.items) |line| {
        var line_iter = std.mem.splitAny(u8, line, " ");
        _ = line_iter.next();
        var time = line_iter.next().?;
        time = time[0 .. time.len - 1];
        const wakes_or_Guard_or_falls = line_iter.next().?;

        switch (wakes_or_Guard_or_falls[0]) {
            'w' => {
                if (std.mem.eql(u8, time[0..2], "23")) {
                    continue;
                } else {
                    const minute = try std.fmt.parseInt(usize, time[3..], 10);
                    for (cur_fall_asleep_time..minute) |i| {
                        ary[cur_guard][i] += 1;
                    }
                }
            },
            'f' => {
                if (std.mem.eql(u8, time[0..2], "23")) {
                    cur_fall_asleep_time = 0;
                } else {
                    const minute = try std.fmt.parseInt(usize, time[3..], 10);
                    cur_fall_asleep_time = minute;
                }
            },
            'G' => {
                const id = try std.fmt.parseInt(usize, line_iter.next().?[1..], 10);
                if (reverse_map.get(id)) |index| {
                    cur_guard = index;
                } else {
                    cur_guard = cur_guard_index;
                    try map.put(cur_guard, id);
                    try reverse_map.put(id, cur_guard);
                    cur_guard_index += 1;
                }
                if (std.mem.eql(u8, time[0..2], "23")) {
                    cur_start_time = 0;
                } else {
                    const minute = try std.fmt.parseInt(usize, time[3..], 10);
                    cur_start_time = minute;
                }
            },
            else => continue,
        }
    }
    var highest_index: usize = 0;
    var highest_sum: usize = 0;
    var highest_minute_slept: usize = 0;
    var highest_minute_max: usize = 0;
    var highest_minute_max_index: usize = 0;
    var highest_minute_guard_index: usize = 0;
    for (ary, 0..ary.len) |row, i| {
        var highest_minute_slept_per_guard: usize = 0;
        var minute_max_index: usize = 0;
        var minute_max: usize = 0;
        var sum: usize = 0;
        for (row, 0..row.len) |num, j| {
            sum += num;
            if (num >= minute_max) {
                minute_max = num;
                highest_minute_slept_per_guard = j;
                minute_max_index = j;
            }
        }
        if (sum > highest_sum) {
            highest_sum = sum;
            highest_index = i;
            highest_minute_slept = highest_minute_slept_per_guard;
        }
        if (minute_max > highest_minute_max) {
            highest_minute_guard_index = i;
            highest_minute_max = minute_max;
            highest_minute_max_index = minute_max_index;
        }
    }
    if (map.get(highest_index)) |id| {
        std.debug.print("{d} * {d} = {d}\n", .{ id, highest_minute_slept, id * highest_minute_slept });
    }
    if (map.get(highest_minute_guard_index)) |id| {
        std.debug.print("{d} * {d} = {d}\n", .{ id, highest_minute_max_index, id * highest_minute_max_index });
    }
}

pub fn sort_by_date_time(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !std.ArrayList([]const u8) {
    var ary: std.ArrayList([]const u8) = .empty;
    while (lines.next()) |line| {
        if (line.len > 0) {
            try ary.append(allocator, line);
        }
    }

    std.sort.insertion([]const u8, ary.items, {}, earlier);
    return ary;
    // std.mem.sortContext(a: usize, b: usize, context: anytype)
}

pub fn earlier(_: void, line1: []const u8, line2: []const u8) bool {
    const date1 = line1[1..11];
    const date2 = line2[1..11];
    const month1 = std.fmt.parseInt(usize, date1[5..7], 10) catch return false;
    const month2 = std.fmt.parseInt(usize, date2[5..7], 10) catch return false;
    if (month1 == month2) {
        const day1 = std.fmt.parseInt(usize, date1[8..], 10) catch return false;
        const day2 = std.fmt.parseInt(usize, date2[8..], 10) catch return false;
        if (day1 == day2) {
            const time1 = line1[12..17];
            const time2 = line2[12..17];
            const hour1 = std.fmt.parseInt(usize, time1[0..2], 10) catch return false;
            const hour2 = std.fmt.parseInt(usize, time2[0..2], 10) catch return false;
            if (hour1 == hour2) {
                const minute1 = std.fmt.parseInt(usize, time1[3..], 10) catch return false;
                const minute2 = std.fmt.parseInt(usize, time2[3..], 10) catch return false;
                return minute1 < minute2;
            }
            return hour1 < hour2;
        }
        return day1 < day2;
    }
    return month1 < month2;
}

pub fn time_to_number(time: []const u8) !?usize {
    if (std.mem.eql(time[0..2], "23")) {
        return 0;
    }
    return try std.fmt.parseInt(usize, time[2..4]);
}

test "sorting" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d4/input.txt");
    const ary = try sort_by_date_time(allocator, &lines);
    for (ary.items) |line| {
        std.debug.print("{s}\n", .{line});
    }
}

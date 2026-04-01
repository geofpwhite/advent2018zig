const std = @import("std");
const parse = @import("./util.zig").parse;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d8/input.txt");
    // var lines = try parse(allocator, "d4/test.txt");
    const line = lines.next().?;
    try part1and2(allocator, line);
}

pub fn part1and2(allocator: std.mem.Allocator, line: []const u8) !void {
    var iter = std.mem.splitAny(u8, line, " ");
    var ary: std.ArrayList(usize) = .empty;
    defer ary.deinit(allocator);
    while (iter.next()) |val| {
        const num = std.fmt.parseInt(usize, val, 10) catch continue;
        try ary.append(allocator, num);
    }
    const ret = get_metadata(ary.items, 0);
    std.debug.print("{d} {d}\n", .{ ret[0], ret[1] });

    const ret2 = try get_metadata_2(allocator, ary.items, 0);
    std.debug.print("{d} {d}\n", .{ ret2[0], ret2[1] });
}

// should return [number,next index to check]
pub fn get_metadata(nums: []usize, index: usize) [2]usize {
    var ret: [2]usize = std.mem.zeroes([2]usize);
    switch (nums[index]) {
        0 => {
            for (index + 2..(index + 2 + nums[index + 1])) |i|
                ret[0] += nums[i];
            ret[1] = index + 2 + nums[index + 1];
            return ret;
        },
        else => {
            var num_children = nums[index];
            const num_metadata_entries = nums[index + 1];
            var next_index = index + 2;
            while (num_children > 0) {
                const child_metadata = get_metadata(nums, next_index);
                ret[0] += child_metadata[0];
                next_index = child_metadata[1];
                num_children -= 1;
            }
            for (next_index..next_index + num_metadata_entries) |i| {
                ret[0] += nums[i];
            }
            ret[1] = next_index + num_metadata_entries;
            return ret;
        },
    }
}
pub fn get_metadata_2(allocator: std.mem.Allocator, nums: []usize, index: usize) ![2]usize {
    var ret: [2]usize = std.mem.zeroes([2]usize);
    switch (nums[index]) {
        0 => {
            for (index + 2..(index + 2 + nums[index + 1])) |i|
                ret[0] += nums[i];
            ret[1] = index + 2 + nums[index + 1];
            return ret;
        },
        else => {
            const num_children = nums[index];
            var child_scores: []usize = try allocator.alloc(usize, num_children);
            defer allocator.free(child_scores);
            const num_metadata_entries = nums[index + 1];
            var next_index = index + 2;
            var cur_child: usize = 0;
            while (num_children > cur_child) {
                const child_metadata = try get_metadata_2(allocator, nums, next_index);
                child_scores[cur_child] = child_metadata[0];
                next_index = child_metadata[1];
                cur_child += 1;
            }
            for (next_index..next_index + num_metadata_entries) |i| {
                const child_index = nums[i] - 1;
                if (child_index >= child_scores.len)
                    continue
                else
                    ret[0] += child_scores[nums[i] - 1];
            }
            ret[1] = next_index + num_metadata_entries;
            return ret;
        },
    }
}

const node = struct {
    metadata: []i64,
};

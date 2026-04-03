const std = @import("std");
const parse = @import("./util.zig").parse;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d9/input.txt");
    const line = lines.next().?;
    var split_line = std.mem.splitAny(u8, line, " ");
    const num_players = try std.fmt.parseInt(usize, split_line.next().?, 10);
    var largest_marble: usize = 0;
    while (split_line.next()) |word| {
        largest_marble = std.fmt.parseInt(usize, word, 10) catch continue;
    }
    try part1(allocator, num_players, largest_marble);
    try part1(allocator, num_players, largest_marble * 100);
    lines.reset();
}

pub fn part1(allocator: std.mem.Allocator, num_players: usize, largest_marble: usize) !void {
    var scores: []usize = try allocator.alloc(usize, num_players);
    defer allocator.free(scores);
    @memset(scores, 0);
    var marble_circle = try allocator.create(marble_spot);
    marble_circle.left = marble_circle;
    marble_circle.right = marble_circle;
    var cur_marble = marble_circle;
    var cur_player: usize = 0;

    for (1..largest_marble + 1) |cur_value| {
        if (cur_value % 23 == 0) {
            var to_remove = cur_marble.left.left.left.left.left.left.left;
            to_remove.left.right = to_remove.right;
            to_remove.right.left = to_remove.left;
            scores[cur_player] += cur_value + to_remove.value;
            cur_marble = to_remove.right;
        } else {
            var one_clockwise = cur_marble.right;
            var two_clockwise = one_clockwise.right;
            var new_marble = try allocator.create(marble_spot);
            new_marble.value = cur_value;
            new_marble.left = one_clockwise;
            new_marble.right = two_clockwise;
            one_clockwise.right = new_marble;
            two_clockwise.left = new_marble;
            cur_marble = new_marble;
        }
        cur_player = (cur_player + 1) % num_players;
    }

    var max: usize = 0;
    for (scores) |score| {
        max = @max(score, max);
    }
    std.debug.print("{d}\n", .{max});
}

const marble_spot = struct {
    left: *marble_spot,
    right: *marble_spot,
    value: usize,
};

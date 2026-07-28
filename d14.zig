const std = @import("std");
const input: usize = 640441;
// const input: usize = 59414;
// const input: usize = 9;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // try part1(allocator);
    try part2(allocator);
}

fn part1(allocator: std.mem.Allocator) !void {
    var scoreboard: std.ArrayList(usize) = .empty;
    try scoreboard.append(allocator, 3);
    try scoreboard.append(allocator, 7);
    std.debug.print("{any}\n", .{scoreboard.items});
    var elf1i: usize, var elf2i: usize = .{ 0, 1 };
    while (scoreboard.items.len < input + 10) {
        const elf1score: usize = scoreboard.items[elf1i];
        const elf2score: usize = scoreboard.items[elf2i];
        const new_score: usize = elf1score + elf2score;
        // std.debug.print("{d} + {d} = {d}\n", .{ elf1score, elf2score, new_score });
        if (new_score >= 10) {
            try scoreboard.append(allocator, new_score / 10);
            try scoreboard.append(allocator, new_score % 10);
        } else {
            try scoreboard.append(allocator, new_score);
        }
        elf1i = (elf1i + elf1score + 1) % scoreboard.items.len;
        elf2i = (elf2i + elf2score + 1) % scoreboard.items.len;
    }
    for (input..input + 10) |i| {
        std.debug.print("{d}", .{scoreboard.items[i]});
    }
    std.debug.print("\n", .{});
}

fn part2(allocator: std.mem.Allocator) !void {
    var scoreboard: std.ArrayList(usize) = .empty;
    try scoreboard.append(allocator, 3);
    try scoreboard.append(allocator, 7);
    std.debug.print("{any}\n", .{scoreboard.items});
    var elf1i: usize, var elf2i: usize = .{ 0, 1 };
    while (!ends_with_input(scoreboard.items) and !ends_with_input(scoreboard.items[0 .. scoreboard.items.len - 1])) {
        const elf1score: usize = scoreboard.items[elf1i];
        const elf2score: usize = scoreboard.items[elf2i];
        const new_score: usize = elf1score + elf2score;
        // std.debug.print("{d} + {d} = {d}\n", .{ elf1score, elf2score, new_score });
        if (new_score >= 10) {
            try scoreboard.append(allocator, new_score / 10);
            try scoreboard.append(allocator, new_score % 10);
        } else {
            try scoreboard.append(allocator, new_score);
        }
        elf1i = (elf1i + elf1score + 1) % scoreboard.items.len;
        elf2i = (elf2i + elf2score + 1) % scoreboard.items.len;
    }
    std.debug.print("{d}\n", .{scoreboard.items.len - 6});
    for (0..10) |i| {
        std.debug.print("{d}", .{scoreboard.items[scoreboard.items.len - 10 + i]});
    }
}

fn ends_with_input(nums: []usize) bool {
    var num = input;
    var index = nums.len - 1;
    while (num > 0) {
        if (index < 0 or nums[index] != num % 10) {
            return false;
        }
        index -= 1;
        num /= 10;
    }
    return true;
}

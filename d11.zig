const std = @import("std");

const input: usize = 4172;
pub fn main() !void {
    try part1and2();
}

fn part1and2() !void {
    var grid: [299][299]i64 = std.mem.zeroes([299][299]i64);
    for (1..300) |i|
        for (1..300) |j| {
            const rack_id: usize = (i + 10);
            var pwr_lvl: i64 = @intCast(rack_id * j);
            pwr_lvl += input;
            pwr_lvl *= @intCast(rack_id);
            pwr_lvl = @mod(@divFloor(pwr_lvl, 100), 10);
            pwr_lvl -= 5;
            grid[i - 1][j - 1] = pwr_lvl;
        };
    var max: i64 = 0;
    var mi: usize = 0;
    var mj: usize = 0;
    for (0..296) |i|
        for (0..296) |j| {
            var total_pwr: i64 = 0;
            for (i..i + 3) |ii| for (j..j + 3) |ij| {
                total_pwr += grid[ii][ij];
            };
            if (total_pwr > max) {
                max = total_pwr;
                mi = i + 1;
                mj = j + 1;
            }
        };
    std.debug.print("{d},{d}\n", .{ mi, mj });
    max = 0;
    mi = 0;
    mj = 0;
    var msize: usize = 0;
    var larger_power: i64 = std.math.minInt(i64);
    for (0..299) |i|
        for (0..299) |j| {
            const largest_possible_size = @min(299 - i, 299 - j);
            for (0..largest_possible_size) |inv_size| {
                const size = largest_possible_size - inv_size;
                const pwr = square_power(grid, i, j, size) orelse std.math.minInt(i64);
                if (pwr > max) {
                    mi = i + 1;
                    mj = j + 1;
                    msize = size;
                    max = pwr;
                    std.debug.print("{d},{d},{d} = {d}\n", .{ mi, mj, msize, max });
                } // else if (larger_power > pwr) break :inner;
                larger_power = pwr;
            }
        };
    std.debug.print("{d},{d},{d} = {d}\n", .{ mi, mj, msize, max });
}

fn to_subtract(grid: [299][299]i64, i: usize, j: usize, size: usize) ?i64 {
    var sum:i64 = 0;
    for (j..j+size) |ij
}

fn square_power(grid: [299][299]i64, i: usize, j: usize, size: usize) ?i64 {
    if (i + size > 299 or j + size > 299) return null;
    var pwr: i64 = 0;
    for (i..i + size) |ii| for (j..j + size) |ij| {
        pwr += grid[ii][ij];
    };
    return pwr;
}

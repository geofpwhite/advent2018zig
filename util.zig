const std = @import("std");

pub fn parse(allocator: std.mem.Allocator, path: []const u8) !std.mem.SplitIterator(u8, .any) {
    const input_buffer = try allocator.alloc(u8, 5028);
    const input = std.fs.cwd().readFile(path, input_buffer) catch |err| {
        std.debug.print("Failed to read input file: {}\n", .{err});
        return err;
    };
    return std.mem.splitAny(u8, input, "\n");
}

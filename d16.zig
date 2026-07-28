const std = @import("std");
const parse = @import("./util.zig").parse;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d16/input.txt");
    // var lines = try parse(allocator, "d16/test.txt");
    var instructions: std.ArrayList(Instruction) = .empty;
    var part2instructions: std.ArrayList(Instruction) = .empty;
    var instr: Instruction = .{
        .after = .{
            .r0 = 0,
            .r1 = 0,
            .r2 = 0,
            .r3 = 0,
        },
        .before = .{
            .r0 = 0,
            .r1 = 0,
            .r2 = 0,
            .r3 = 0,
        },
        .opcode = 0,
        .A = 0,
        .B = 0,
        .C = 0,
    };
    var index: usize = 0;
    // std.debug.print("{s}\n", .{std.mem.trim(u8, "1]", "\n\r[] ")});
    while (lines.next()) |line| {
        index += 1;
        // std.debug.print("{d}\n", .{index});
        if (line.len == 0) {
            try instructions.append(allocator, instr);
            continue;
        }
        if (index > 3237) {
            var iter = std.mem.splitAny(u8, line, " ");
            var i: usize = 0;
            while (iter.next()) |num| {
                const nu = try std.fmt.parseInt(i64, std.mem.trim(u8, num, "\n\r[] "), 10);
                switch (i) {
                    0 => instr.opcode = nu,
                    1 => instr.A = nu,
                    2 => instr.B = nu,
                    3 => instr.C = nu,
                    else => unreachable,
                }
                i += 1;
            }
            try part2instructions.append(allocator, instr);

            continue;
        }
        if (std.mem.eql(u8, line[0..7], "Before:")) {
            var iter = std.mem.splitAny(u8, line[8..], ",");
            var i: usize = 0;
            while (iter.next()) |num| {
                // std.debug.print("{s} vs. {s}|\n", .{ std.mem.trim(u8, num, "\n\r[] "), num });
                // std.debug.print("{s} {d}\n", .{ num, num.len });
                var trimmed = std.mem.trim(u8, num, "\n\r[] ");
                if (trimmed[trimmed.len - 1] == ']') {
                    trimmed = trimmed[0 .. trimmed.len - 1];
                }
                const nu = try std.fmt.parseInt(i64, trimmed, 10);
                switch (i) {
                    0 => instr.before.r0 = nu,
                    1 => instr.before.r1 = nu,
                    2 => instr.before.r2 = nu,
                    3 => instr.before.r3 = nu,
                    else => unreachable,
                }
                i += 1;
            }
            continue;
        }
        if (std.mem.eql(u8, line[0..6], "After:")) {
            var iter = std.mem.splitAny(u8, line[7..], ",");
            var i: usize = 0;
            while (iter.next()) |num| {
                const nu = try std.fmt.parseInt(i64, std.mem.trim(u8, num, "\n\r[] "), 10);
                switch (i) {
                    0 => instr.after.r0 = nu,
                    1 => instr.after.r1 = nu,
                    2 => instr.after.r2 = nu,
                    3 => instr.after.r3 = nu,
                    else => unreachable,
                }
                i += 1;
            }
            continue;
        }
        var iter = std.mem.splitAny(u8, line, " ");
        var i: usize = 0;
        while (iter.next()) |num| {
            const nu = try std.fmt.parseInt(i64, std.mem.trim(u8, num, "\n\r[] "), 10);
            switch (i) {
                0 => instr.opcode = nu,
                1 => instr.A = nu,
                2 => instr.B = nu,
                3 => instr.C = nu,
                else => unreachable,
            }
            i += 1;
        }
    }

    var sum: usize = 0;
    var possibleOpcode: std.AutoHashMap(i64, []Opcode) = .init(allocator);

    for (instructions.items[0..]) |*inst| {
        var to_remove: std.ArrayList(usize) = .empty;
        const pos = try inst.possible();
        if (pos >= 3) sum += 1;
        const pos_list = try inst.possible_list(allocator);
        if (pos_list.len == 0) continue;
        const op: i64 = inst.opcode;
        if (possibleOpcode.get(op) == null) {
            try possibleOpcode.put(op, pos_list);
            continue;
        }
        const po = possibleOpcode.get(op).?;
        std.debug.print("{any} po {d} op\n", .{ po, op });
        var good: bool = false;
        for (po, 0..po.len) |opc, i| {
            for (pos_list) |p| {
                if (p == opc) {
                    good = true;
                    break;
                }
            }
            if (!good) {
                try to_remove.append(allocator, i);
            }

            // var new = try allocator.alloc(Opcode,po.len+1);
            // @memcpy(new[0..new.len-1],po);

        }
        var new_po: std.ArrayList(Opcode) = .empty;
        var remove_index: usize = 0;
        for (po, 0..po.len) |p, i| {
            if (remove_index < to_remove.items.len) {
                if (i == to_remove.items[remove_index]) {
                    remove_index += 1;
                    continue;
                }
            }
            try new_po.append(allocator, p);
        }
        std.debug.print("pos {d} op {d} new_po {any} to_remove {any} old {any} cur {any}\n", .{ pos, op, new_po.items, to_remove.items, po, pos_list });
        try possibleOpcode.put(op, new_po.items);
    }
    std.debug.print("{d} \n{any}\n{any}\n", .{ sum, instructions.items[0], instructions.items[instructions.items.len - 1] });
    for (0..32) |_| {
        for (0..16) |opc| {
            const x = possibleOpcode.get(@intCast(opc));
            if (x) |opcodes| {
                if (opcodes.len == 1) {
                    for (0..16) |opc2| {
                        if (opc == opc2) continue;
                        const y = possibleOpcode.get(@intCast(opc2));
                        var remove: usize = std.math.maxInt(usize);

                        if (y) |opcs2| {
                            for (opcs2, 0..opcs2.len) |opc3, i| {
                                if (opc3 == opcodes[0]) {
                                    remove = i;
                                    break;
                                }
                            }
                            if (remove < opcs2.len) {
                                var new = try allocator.alloc(Opcode, opcs2.len - 1);
                                @memcpy(new[0..remove], opcs2[0..remove]);
                                @memcpy(new[remove..], opcs2[remove + 1 ..]);
                                std.debug.print("{any} new\n", .{new});
                                try possibleOpcode.put(@intCast(opc2), new);
                            }
                        }
                    }
                }
            }
        }
    }
    var real_opcodes = std.AutoHashMap(i64, Opcode).init(allocator);
    for (0..16) |opc| {
        const x = possibleOpcode.get(@intCast(opc));
        if (x) |opcodes| {
            std.debug.print("{any} {d}\n", .{ opcodes, opc });
            try real_opcodes.put(@intCast(opc), opcodes[0]);
        }
    }
    var start: Device = .{
        .r0 = 0,
        .r1 = 0,
        .r2 = 0,
        .r3 = 0,
    };
    for (part2instructions.items) |inst| {
        const real_opcode = real_opcodes.get(inst.opcode);
        if (real_opcode) |opc| {
            start = start.execute(opc, inst.A, inst.B, inst.C);
        }
    }
    std.debug.print("{any}\n", .{start});
}

const Device = struct {
    r0: i64,
    r1: i64,
    r2: i64,
    r3: i64,
    fn execute(self: *Device, opcode: Opcode, a: i64, b: i64, c: i64) Device {
        var dup = self.*;
        const ra = switch (a) {
            0 => &dup.r0,
            1 => &dup.r1,
            2 => &dup.r2,
            3 => &dup.r3,
            else => unreachable,
        };
        const rb = switch (b) {
            0 => &dup.r0,
            1 => &dup.r1,
            2 => &dup.r2,
            3 => &dup.r3,
            else => unreachable,
        };
        const rc = switch (c) {
            0 => &dup.r0,
            1 => &dup.r1,
            2 => &dup.r2,
            3 => &dup.r3,
            else => unreachable,
        };
        switch (opcode) {
            .addr => {
                rc.* = ra.* + rb.*;
            },
            .addi => {
                rc.* = ra.* + b;
            },
            .mulr => {
                rc.* = ra.* * rb.*;
            },
            .muli => {
                rc.* = ra.* * b;
            },
            .banr => rc.* = ra.* & rb.*,
            .bani => rc.* = ra.* & b,

            .borr => rc.* = ra.* | rb.*,
            .bori => rc.* = ra.* | b,
            .setr => rc.* = ra.*,
            .seti => rc.* = a,
            .gtir => rc.* = if (a > rb.*) 1 else 0,
            .gtri => rc.* = if (ra.* > b) 1 else 0,
            .gtrr => rc.* = if (ra.* > rb.*) 1 else 0,
            .eqir => rc.* = if (a == rb.*) 1 else 0,
            .eqri => rc.* = if (ra.* == b) 1 else 0,
            .eqrr => rc.* = if (ra.* == rb.*) 1 else 0,
        }
        // std.debug.print("{any}\n{any}\n", .{ self.*, dup });
        return dup;
    }

    fn eql(self: Device, other: Device) bool {
        return self.r0 == other.r0 and self.r1 == other.r1 and self.r2 == other.r2 and self.r3 == other.r3;
    }
};

const Instruction = struct {
    before: Device,
    after: Device,
    opcode: i64,
    A: i64,
    B: i64,
    C: i64,
    fn possible(self: *Instruction) !usize {
        var sum: usize = 0;
        for (Opcodes) |opc| {
            const d = self.before.execute(opc, self.A, self.B, self.C);
            if (d.eql(self.after)) {
                sum += 1;
                // std.debug.print("{any} cmp\n{any}\n{any}\n\n", .{ opc, self.after, d });
            }
        }
        return sum;
    }
    fn possible_list(self: *Instruction, allocator: std.mem.Allocator) ![]Opcode {
        var ary: std.ArrayList(Opcode) = .empty;
        for (Opcodes) |opc| {
            const d = self.before.execute(opc, self.A, self.B, self.C);
            if (d.eql(self.after)) {
                try ary.append(allocator, opc);
                // std.debug.print("{any} cmp\n{any}\n{any}\n\n", .{ opc, self.after, d });
            }
        }
        return ary.items;
    }
};

const Opcode = enum {
    addr,
    addi,
    mulr,
    muli,
    banr,
    bani,
    borr,
    bori,
    setr,
    seti,
    gtir,
    gtri,
    gtrr,
    eqir,
    eqri,
    eqrr,
};

const Opcodes = [_]Opcode{
    .addr,
    .addi,
    .mulr,
    .muli,
    .banr,
    .bani,
    .borr,
    .bori,
    .setr,
    .seti,
    .gtir,
    .gtri,
    .gtrr,
    .eqir,
    .eqri,
    .eqrr,
};

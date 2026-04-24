const std = @import("std");
const parse = @import("util.zig").parse;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var lines = try parse(allocator, "d13/input.txt");
    const nodes, const carts = try Nodes_and_carts(allocator, &lines);
    // const nodes = ret.@"0";
    // var iter = nodes.valueIterator();
    // while (iter.next()) |n| {
    //     std.debug.print("node {any}\n", .{n.*});
    // }
    try part1(allocator, nodes, carts);
}

fn part1(allocator: std.mem.Allocator, nodes: std.AutoHashMap(Coords, *Node), carts: []Cart) !void {
    var cur_steps: []usize = try allocator.alloc(usize, carts.len);
    var cur_carts: std.AutoHashMap(Coords, void) = .init(allocator);
    for (carts) |cart| {
        try cur_carts.put(cart.coords, {});
    }
    var first_crash = Coords{ .x = 0, .y = 0 };
    @memset(cur_steps, 0);
    outer: while (true) {
        for (0..carts.len) |i| {
            std.debug.print("cart {any}\n", .{carts[i]});
            const n = nodes.get(carts[i].coords);
            const c = carts[i];
            if (n) |node| {
                try node.print();
                if (is_intersection(node.*)) {
                    const choice_dir = try choice_to_dir(cur_steps[i]);
                    cur_steps[i] = (cur_steps[i] + 1) % 3;
                    carts[i].dir = try new_direction(c.dir, choice_dir);
                    carts[i].coords = move(c.coords, carts[i].dir);
                } // aka is a +
                else {
                    // node is a corner

                    //br
                    if (node.l) |_| if (node.u) |_| {
                        if (c.dir == .r) {
                            carts[i].dir = .u;
                            carts[i].coords = move(c.coords, carts[i].dir);
                        } else if (c.dir == .d) {
                            carts[i].dir = .l;
                            carts[i].coords = move(c.coords, carts[i].dir);
                        } else {
                            unreachable;
                        }
                    };
                    //bl
                    if (node.r) |_| if (node.u) |_| {
                        if (c.dir == .l) {
                            carts[i].dir = .u;
                            carts[i].coords = move(c.coords, carts[i].dir);
                        } else if (c.dir == .d) {
                            carts[i].dir = .r;
                            carts[i].coords = move(c.coords, carts[i].dir);
                        } else {
                            unreachable;
                        }
                    };
                    //tl
                    if (node.r) |_| if (node.d) |_| {
                        if (c.dir == .l) {
                            carts[i].dir = .d;
                            carts[i].coords = move(c.coords, carts[i].dir);
                        } else if (c.dir == .u) {
                            carts[i].dir = .r;
                            carts[i].coords = move(c.coords, carts[i].dir);
                        } else {
                            try node.print();

                            unreachable;
                        }
                    };
                    //tr
                    if (node.d) |_| if (node.l) |_| {
                        if (c.dir == .r) {
                            carts[i].dir = .d;
                            carts[i].coords = move(c.coords, carts[i].dir);
                        } else if (c.dir == .u) {
                            carts[i].dir = .l;
                            carts[i].coords = move(c.coords, carts[i].dir);
                        } else {
                            unreachable;
                        }
                    };
                }
            } else {
                carts[i].coords = move(c.coords, c.dir);
            }
            _ = cur_carts.remove(c.coords);
            if (cur_carts.get(carts[i].coords)) |_| {
                first_crash = carts[i].coords;
                break :outer;
            }
            try cur_carts.put(carts[i].coords, {});
        }
    }
    std.debug.print("{any}", .{first_crash});
}

fn move(coords: Coords, dir: Direction) Coords {
    var c: Coords = .{ .x = coords.x, .y = coords.y };
    std.debug.print("{any}\n", .{c});
    switch (dir) {
        .u => c.x -= 1,
        .d => c.x += 1,
        .l => c.y -= 1,
        .r => c.y += 1,
    }
    return c;
}
fn choice_to_dir(choice: usize) !Direction {
    switch (choice) {
        0 => return .l,
        1 => return .u,
        2 => return .r,
        else => unreachable,
    }
}
fn is_intersection(node: Node) bool {
    return node.l != null and node.r != null and node.u != null and node.d != null;
}
fn new_direction(cur_dir: Direction, relative_dir: Direction) !Direction {
    switch (cur_dir) {
        .l => {
            switch (relative_dir) {
                .l => return .d,
                .r => return .u,
                .u => return .l,
                else => unreachable,
            }
        },
        .r => {
            switch (relative_dir) {
                .l => return .u,
                .r => return .d,
                .u => return .r,
                else => unreachable,
            }
        },
        .u => {
            return relative_dir;
        },
        .d => {
            switch (relative_dir) {
                .l => return .r,
                .r => return .l,
                .u => return .d,
                else => unreachable,
            }
        },
    }
}
fn Nodes_and_carts(allocator: std.mem.Allocator, lines: *std.mem.SplitIterator(u8, .any)) !struct { std.AutoHashMap(Coords, *Node), []Cart } {
    var Nodes: std.AutoHashMap(Coords, *Node) = .init(allocator);
    var Carts: std.ArrayList(Cart) = .empty;
    var line_grid: std.ArrayList([]const u8) = .empty;
    var x: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        try line_grid.append(allocator, line);
    }
    const empty_line: []u8 = try allocator.alloc(u8, line_grid.items[0].len);
    @memset(empty_line, ' ');
    try line_grid.append(allocator, empty_line);
    lines.reset();
    while (lines.next()) |line| : (x += 1) {
        for (line, 0..) |char, y| {
            switch (char) {
                '>' => {
                    const c: Cart = Cart{ .coords = Coords{ .x = x, .y = y }, .dir = .r };
                    try Carts.append(allocator, c);
                },
                '<' => {
                    const c: Cart = Cart{ .coords = Coords{ .x = x, .y = y }, .dir = .l };
                    try Carts.append(allocator, c);
                },
                'v' => {
                    const c: Cart = Cart{ .coords = Coords{ .x = x, .y = y }, .dir = .d };
                    try Carts.append(allocator, c);
                },
                '^' => {
                    const c: Cart = Cart{ .coords = Coords{ .x = x, .y = y }, .dir = .u };
                    try Carts.append(allocator, c);
                },
                '/', '\\', '+' => {
                    var n: *Node = try allocator.create(Node);
                    n.u = null;
                    n.d = null;
                    n.l = null;
                    n.r = null;
                    n.coords = .{ .x = x, .y = y };
                    try Nodes.put(.{ .x = x, .y = y }, n);
                },
                else => continue,
            }
        }
    }
    for (0..line_grid.items.len) |i| {
        const buf: []u8 = try allocator.alloc(u8, line_grid.items[i].len);
        @memcpy(buf, line_grid.items[i]);
        var changed: usize = 0;
        changed += std.mem.replace(u8, line_grid.items[i], "v", "|", buf);
        changed += std.mem.replace(u8, line_grid.items[i], "^", "|", buf);
        changed += std.mem.replace(u8, line_grid.items[i], ">", "-", buf);
        changed += std.mem.replace(u8, line_grid.items[i], "<", "-", buf);
        std.debug.print("changed {d}\n", .{changed});
        line_grid.items[i] = buf;
    }
    var n_iter = Nodes.valueIterator();
    while (n_iter.next()) |n| {
        var node = n.*;
        const c = node.*.coords;
        switch (line_grid.items[c.x][c.y]) {
            '/' => {
                const t = TypeOfCorner(line_grid.items, c.x, c.y);
                switch (t) {
                    .tl => {
                        var down_c = Coords{ .x = c.x + 1, .y = c.y };
                        var right_c = Coords{ .x = c.x, .y = c.y + 1 };
                        while (line_grid.items[down_c.x][down_c.y] == '|' or std.mem.containsAtLeastScalar(u8, "<>v^", 1, line_grid.items[down_c.x][down_c.y])) {
                            down_c.x += 1;
                        }
                        const down_n = Nodes.get(down_c);
                        if (down_n) |dn| {
                            node.d = dn;
                            dn.u = node;
                        } else {
                            unreachable;
                        }
                        while (line_grid.items[right_c.x][right_c.y] == '-' or std.mem.containsAtLeastScalar(u8, "<>v^", 1, line_grid.items[right_c.x][right_c.y])) {
                            right_c.y += 1;
                        }
                        const right_n = Nodes.get(right_c);
                        if (right_n) |rn| {
                            node.r = rn;
                            rn.l = node;
                        } else {
                            unreachable;
                        }
                        try Nodes.put(node.coords, node);
                    },
                    .br => {
                        var up_c = Coords{ .x = c.x - 1, .y = c.y };
                        var left_c = Coords{ .x = c.x, .y = c.y - 1 };
                        while (line_grid.items[up_c.x][up_c.y] == '|' or std.mem.containsAtLeastScalar(u8, "<>v^", 1, line_grid.items[up_c.x][up_c.y])) {
                            up_c.x -= 1;
                        }
                        const up_n = Nodes.get(up_c);
                        if (up_n) |un| {
                            node.u = un;
                            un.d = node;
                        } else {
                            std.debug.print("{s}\n", .{line_grid.items[up_c.x][up_c.y .. up_c.y + 1]});
                            unreachable;
                        }
                        while (line_grid.items[left_c.x][left_c.y] == '-' or std.mem.containsAtLeastScalar(u8, "<>v^", 1, line_grid.items[up_c.x][up_c.y])) {
                            left_c.y -= 1;
                        }
                        const left_n = Nodes.get(left_c);
                        if (left_n) |ln| {
                            node.l = ln;
                            ln.r = node;
                        } else {
                            unreachable;
                        }
                    },
                    else => unreachable,
                }
            },
            '\\' => {
                const t = TypeOfCorner(line_grid.items, c.x, c.y);
                switch (t) {
                    .bl => {
                        var up_c = Coords{ .x = c.x - 1, .y = c.y };
                        var right_c = Coords{ .x = c.x, .y = c.y + 1 };
                        while (line_grid.items[up_c.x][up_c.y] == '|' or std.mem.containsAtLeastScalar(u8, "<>v^", 1, line_grid.items[up_c.x][up_c.y])) {
                            up_c.x -= 1;
                        }
                        const up_n = Nodes.get(up_c);
                        if (up_n) |un| {
                            node.u = un;
                            un.d = node;
                        } else {
                            unreachable;
                        }
                        while (line_grid.items[right_c.x][right_c.y] == '-' or std.mem.containsAtLeastScalar(u8, "<>v^", 1, line_grid.items[right_c.x][right_c.y])) {
                            right_c.y += 1;
                        }
                        const right_n = Nodes.get(right_c);
                        if (right_n) |rn| {
                            node.r = rn;
                            rn.l = node;
                        } else {
                            unreachable;
                        }
                        try node.print();
                        try Nodes.put(node.coords, node);
                    },
                    .tr => {
                        var down_c = Coords{ .x = c.x + 1, .y = c.y };
                        var left_c = Coords{ .x = c.x, .y = c.y - 1 };
                        while (line_grid.items[down_c.x][down_c.y] == '|' or std.mem.containsAtLeastScalar(u8, "<>v^", 1, line_grid.items[down_c.x][down_c.y])) {
                            down_c.x += 1;
                        }
                        const down_n = Nodes.get(down_c);
                        if (down_n) |dn| {
                            node.d = dn;
                            dn.u = node;
                        } else {
                            unreachable;
                        }
                        while (line_grid.items[left_c.x][left_c.y] == '-' or std.mem.containsAtLeastScalar(u8, "<>v^", 1, line_grid.items[left_c.x][left_c.y])) {
                            left_c.y -= 1;
                        }
                        const left_n = Nodes.get(left_c);
                        if (left_n) |ln| {
                            node.l = ln;
                            ln.r = node;
                        } else {
                            unreachable;
                        }
                    },
                    else => unreachable,
                }
            },
            '+' => {
                var up_c = Coords{ .x = c.x - 1, .y = c.y };
                var right_c = Coords{ .x = c.x, .y = c.y + 1 };
                while (line_grid.items[up_c.x][up_c.y] == '|' or line_grid.items[up_c.x][up_c.y] == 'v' or line_grid.items[up_c.x][up_c.y] == '^') {
                    up_c.x -= 1;
                }
                std.debug.print("{s}\n", .{line_grid.items[up_c.x][up_c.y .. up_c.y + 1]});
                const up_n = Nodes.get(up_c);
                if (up_n) |un| {
                    node.u = un;
                    un.d = node;
                } else {
                    unreachable;
                }
                while (line_grid.items[right_c.x][right_c.y] == '-' or line_grid.items[right_c.x][right_c.y] == '<' or line_grid.items[right_c.x][right_c.y] == '>') {
                    right_c.y += 1;
                }
                const right_n = Nodes.get(right_c);
                if (right_n) |rn| {
                    node.r = rn;
                    rn.l = node;
                } else {
                    unreachable;
                }
                var down_c = Coords{ .x = c.x + 1, .y = c.y };
                var left_c = Coords{ .x = c.x, .y = c.y - 1 };
                while (line_grid.items[down_c.x][down_c.y] == '|' or line_grid.items[down_c.x][down_c.y] == '^' or line_grid.items[down_c.x][down_c.y] == 'v') {
                    down_c.x += 1;
                }
                const down_n = Nodes.get(down_c);
                if (down_n) |dn| {
                    node.d = dn;
                    dn.u = node;
                } else {
                    unreachable;
                }
                while (line_grid.items[left_c.x][left_c.y] == '-' or line_grid.items[left_c.x][left_c.y] == '<' or line_grid.items[left_c.x][left_c.y] == '>') {
                    left_c.y -= 1;
                }
                const left_n = Nodes.get(left_c);
                if (left_n) |ln| {
                    node.l = ln;
                    ln.r = node;
                } else {
                    unreachable;
                }
            },
            else => unreachable,
        }
    }
    return .{ Nodes, Carts.items };
}

fn TypeOfCorner(line_grid: [][]const u8, x: usize, y: usize) CornerType {
    std.debug.print("{d} {d} \n", .{ line_grid.len, line_grid[x].len });
    std.debug.print("{d} {d} \n", .{ x, y });
    switch (line_grid[x][y]) {
        '/' => {
            //top left case
            if ((x < line_grid.len - 1 and
                (line_grid[x + 1][y] == '|' or
                    line_grid[x + 1][y] == '/' or
                    line_grid[x + 1][y] == '\\' or
                    line_grid[x + 1][y] == '+')) and
                (y < line_grid.len - 1 and
                    (line_grid[x][y + 1] == '-' or
                        line_grid[x][y + 1] == '/' or
                        line_grid[x][y + 1] == '\\' or
                        line_grid[x][y + 1] == '+')) and
                ((x == 0 or (line_grid[x - 1][y] != '|' and
                    line_grid[x - 1][y] != '/' and
                    line_grid[x - 1][y] != '\\' and
                    line_grid[x - 1][y] != '+'))) or
                (y == 0 or (line_grid[x][y - 1] != '-' and
                    line_grid[x][y - 1] != '/' and
                    line_grid[x][y - 1] != '\\' and
                    line_grid[x][y - 1] != '+')))
            {
                return .tl;
            } else {
                return .br;
            }
        },
        '\\' => {
            // bottom left case
            if ((x > 0 and
                (line_grid[x - 1][y] == '|' or
                    line_grid[x - 1][y] == '/' or
                    line_grid[x - 1][y] == '\\' or
                    line_grid[x - 1][y] == '+')) and
                (y < line_grid.len - 1 and
                    (line_grid[x][y + 1] == '-' or
                        line_grid[x][y + 1] == '/' or
                        line_grid[x][y + 1] == '\\' or
                        line_grid[x][y + 1] == '+')) and
                ((x == line_grid.len - 1 or (line_grid[x + 1][y] != '|' and
                    line_grid[x + 1][y] != '/' and
                    line_grid[x + 1][y] != '\\' and
                    line_grid[x + 1][y] != '+'))) or
                (y == 0 or (line_grid[x][y - 1] != '-' and
                    line_grid[x][y - 1] != '/' and
                    line_grid[x][y - 1] != '\\' and
                    line_grid[x][y - 1] != '+')))
            {
                return .bl;
            } else {
                return .tr;
            }
        },
        else => unreachable,
    }
}

const CornerType = enum { tr, tl, br, bl };

const Node = struct {
    coords: Coords,
    u: ?*Node,
    d: ?*Node,
    l: ?*Node,
    r: ?*Node,

    fn print(self: *Node) !void {
        std.debug.print("coords: {any} ", .{self.coords});
        if (self.u) |u| {
            std.debug.print("u: {any} ", .{u.coords});
        }
        if (self.d) |d| {
            std.debug.print("d: {any} ", .{d.coords});
        }
        if (self.l) |l| {
            std.debug.print("l: {any} ", .{l.coords});
        }
        if (self.r) |r| {
            std.debug.print("r: {any} ", .{r.coords});
        }
        std.debug.print("\n", .{});
    }
};

const Coords = struct {
    x: usize,
    y: usize,
};

const Cart = struct {
    coords: Coords,
    dir: Direction,
};

const Direction = enum { l, r, u, d };

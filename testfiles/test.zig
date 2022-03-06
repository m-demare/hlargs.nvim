const std = @import("std");

const Struct = struct {
    param_one: i32,
    param_two: f32,
    param_three: []const u8,

    const Self = @This();

    pub fn init(one: i32, two: f32, three: []const u8) Self {
        return Self{
            .param_one = one,
            .param_two = two,
            .param_three = three,
        };
    }
};

pub fn main() !void {
    const s = Struct.init(1, 2.0, "String");
    const pseudo_lamda = struct {
        fn call(@"struct": *const Struct) void {
            printStruct(@"struct");
        }
    }.call;
    pseudo_lamda(&s);

    for (s.param_three) |char| {
        std.log.info("{}", .{char});
    }
}

fn printStruct(s: *const Struct) void {
    std.log.info("{}", .{s.param_one});
    std.log.info("{}", .{s.param_two});
    std.log.info("{s}", .{s.param_three});
}

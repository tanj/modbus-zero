const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const testing = std.testing;
const mb = @import("mbap_types.zig");

pub fn parse_tcp_packet(data: []const u8) mb.TcpAppDataUnit {
    // assert(data.len >= @sizeOf(mb.TcpAppDataUnit));
    // std.debug.print("data.len: {}, sizeof(TcpAppDataUnit): {}\n", .{ data.len, @sizeOf(mb.TcpAppDataUnit) });
    const du: mb.TcpAppDataUnit = .{
        .header = .{
            .transaction_id = mem.readPackedInt(u16, data[0..2], 0, mb.ModbusEndian),
            .protocol_id = mem.readPackedInt(u16, data[2..4], 0, mb.ModbusEndian),
            .length = mem.readPackedInt(u16, data[4..6], 0, mb.ModbusEndian),
            .unit_id = data[6],
        },
        .pdu = .{
            .function_code_type = mb.FunctionCodeType.fromByte(data[7]),
            .data = data[8..],
        },
    };
    // std.debug.print("{}\n", .{du});
    return du;
}

test "Parse Tcp Packet" {
    const packet = [_]u8{ 0xA1, 0xB2, 0xC3, 0xD4, 0, 1, 2, 3, 0xff };
    const expected = mb.TcpAppDataUnit{ .header = .{
        .transaction_id = 0xA1B2,
        .protocol_id = 0xC3D4,
        .length = 1,
        .unit_id = 2,
    }, .pdu = .{
        .function_code_type = .{ .common = mb.FunctionCode.read_holding_register },
        .data = packet[8..],
    } };
    const result = parse_tcp_packet(packet[0..]);
    try testing.expectEqual(expected, result);
}

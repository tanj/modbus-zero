//! Modbus Application Protocol (mbap) Types

const testing = @import("std").testing;

/// MODBUS stardard declares all addresses and data use big-Endian format
pub const ModbusEndian = @import("std").builtin.Endian.big;

/// Public Function Codes as defined in MODBUS Application Protocol v1.1b3
pub const FunctionCode = enum {
    read_discrete_inputs,
    read_coils,
    write_single_coil,
    write_multiple_coils,
    read_input_register,
    read_holding_register,
    write_single_register,
    write_multiple_registers,
    write_read_multiple_registers,
    mask_write_register,
    read_fifo_queue,
    read_file_record,
    write_file_record,
    read_exception_status,
    diagnostic,
    get_com_event_counter,
    get_com_event_log,
    report_server_id,
    read_device_identification,
    encapsulate_interface_transport,
    canopen_general_reference,
    unclassified_43,

    /// returns the function code byte value.
    ///
    /// We use an enum function because public function code 43 (0x2b) has three
    /// different use cases.
    pub fn getCode(self: FunctionCode) u8 {
        return switch (self) {
            FunctionCode.read_discrete_inputs => 2,
            FunctionCode.read_coils => 1,
            FunctionCode.write_single_coil => 5,
            FunctionCode.write_multiple_coils => 15,
            FunctionCode.read_input_register => 4,
            FunctionCode.read_holding_register => 3,
            FunctionCode.write_single_register => 6,
            FunctionCode.write_multiple_registers => 16,
            FunctionCode.write_read_multiple_registers => 23,
            FunctionCode.mask_write_register => 22,
            FunctionCode.read_fifo_queue => 24,
            FunctionCode.read_file_record => 20,
            FunctionCode.write_file_record => 21,
            FunctionCode.read_exception_status => 7,
            FunctionCode.diagnostic => 8,
            FunctionCode.get_com_event_counter => 11,
            FunctionCode.get_com_event_log => 12,
            FunctionCode.report_server_id => 17,
            FunctionCode.read_device_identification,
            FunctionCode.encapsulate_interface_transport,
            FunctionCode.canopen_general_reference,
            FunctionCode.unclassified_43,
            => 43,
        };
    }

    pub fn fromByte(val: u8) ?FunctionCode {
        return switch (val) {
            1 => FunctionCode.read_coils,
            2 => FunctionCode.read_discrete_inputs,
            3 => FunctionCode.read_holding_register,
            4 => FunctionCode.read_input_register,
            5 => FunctionCode.write_single_coil,
            6 => FunctionCode.write_single_register,
            7 => FunctionCode.read_exception_status,
            8 => FunctionCode.diagnostic,
            11 => FunctionCode.get_com_event_counter,
            12 => FunctionCode.get_com_event_log,
            15 => FunctionCode.write_multiple_coils,
            16 => FunctionCode.write_multiple_registers,
            17 => FunctionCode.report_server_id,
            20 => FunctionCode.read_file_record,
            21 => FunctionCode.write_file_record,
            22 => FunctionCode.mask_write_register,
            23 => FunctionCode.write_read_multiple_registers,
            24 => FunctionCode.read_fifo_queue,
            43 => FunctionCode.unclassified_43,
            else => null,
        };
    }
};

const FunctionCodeTag = enum {
    common,
    public,
    user,
    err,
};

pub const FunctionCodeType = union(FunctionCodeTag) {
    common: FunctionCode,
    public: u8,
    user: u8,
    err: u8,

    pub fn fromByte(val: u8) FunctionCodeType {
        if (FunctionCode.fromByte(val)) |fc| {
            return FunctionCodeType{ .common = fc };
        }
        return switch (val) {
            1...64,
            73...99,
            111...127,
            => FunctionCodeType{ .public = val },
            65...72,
            100...110,
            => FunctionCodeType{ .user = val },
            else => FunctionCodeType{ .err = val },
        };
    }

    /// Modbus Error Response function code is the function code + 0x80. This
    /// function converts that error function code to the original function code.
    pub fn fromError(val: u8) FunctionCodeType {
        return FunctionCodeType.fromByte(val & 0x7f);
    }
};

pub const ExceptionCode = enum(u8) {
    illegal_function = 0x01,
    illegal_data_address = 0x02,
    illegal_data_value = 0x03,
    server_device_failure = 0x04,
    acknowledge = 0x05,
    server_device_busy = 0x06,
    memory_parity_error = 0x08,
    gateway_path_unavailable = 0xa,
    gateway_target_device_failed_to_respond = 0x0b,

    fn fromByte(val: u8) ?ExceptionCode {
        return switch (val) {
            0x01 => ExceptionCode.illegal_function,
            0x02 => ExceptionCode.illegal_data_address,
            0x03 => ExceptionCode.illegal_data_value,
            0x04 => ExceptionCode.server_device_failure,
            0x05 => ExceptionCode.acknowledge,
            0x06 => ExceptionCode.server_device_busy,
            0x08 => ExceptionCode.memory_parity_error,
            0x0a => ExceptionCode.gateway_path_unavailable,
            0x0b => ExceptionCode.gateway_target_device_failed_to_respond,
            else => null,
        };
    }
};

const ExceptionCodeTag = enum {
    exception,
    unknown,
};

pub const ExceptionCodeType = union(ExceptionCodeTag) {
    exception: ExceptionCode,
    unknown: u8,

    pub fn fromByte(val: u8) ExceptionCodeType {
        if (ExceptionCode.fromByte(val)) |ec| {
            return ExceptionCodeType{ .exception = ec };
        } else {
            return ExceptionCodeType{ .unknown = val };
        }
    }
};

pub const ProtocolDataUnit = struct {
    function_code_type: FunctionCodeType,
    data: []const u8, // max length 253 bytes
};

/// Modbus App TCP Header
pub const TcpHeader = struct {
    transaction_id: u16, // initialized by client, copied to server reply
    protocol_id: u16, // initialized by client, copied to server reply
    length: u16, // initialized by client and server
    unit_id: u8, // initialized by client, copied to server reply
};

/// TCP Application Data Unit
pub const TcpAppDataUnit = struct {
    header: TcpHeader,
    pdu: ProtocolDataUnit,
};

/// Modbus App Serial Header
pub const SerialHeader = struct {
    unit_id: u8, // initialized by client, copied to server reply
};

/// Serial Application Data Unit
pub const SerialAppDataUnit = struct {
    address: u8,
    pdu: ProtocolDataUnit,
    checksum: u16,
};

pub const Request = struct {
    function_code_type: FunctionCodeType,
    starting_address: u16,
    quantity: u16,
};

pub const ErrorResponse = struct {
    function_code: FunctionCodeType,
    exception_code: ExceptionCodeType,
};

test "FunctionCode.getCode" {
    const can = FunctionCode.canopen_general_reference;
    try testing.expect(43 == can.getCode());
    try testing.expect(3 == FunctionCode.read_holding_register.getCode());
}

test "ExceptionCodeType" {
    const ec1 = ExceptionCodeType.fromByte(1);
    try testing.expect(ExceptionCode.illegal_function == ec1.exception);

    const ec2 = ExceptionCodeType.fromByte(7);
    try testing.expect(7 == ec2.unknown);
}

test "FunctionCodeType.fromByte" {
    var fc: u8 = 0;
    while (true) {
        fc += 1;
        const fct = FunctionCodeType.fromByte(fc);
        _ = fct;
        if (fc == 255)
            break;
    }
    var fct = FunctionCodeType.fromByte(0);
    try testing.expect(fct.err == 0);
    fct = FunctionCodeType.fromByte(3);
    try testing.expect(fct.common == FunctionCode.read_holding_register);
    fct = FunctionCodeType.fromByte(64);
    try testing.expect(fct.public == 64);
    fct = FunctionCodeType.fromByte(65);
    try testing.expect(fct.user == 65);
    fct = FunctionCodeType.fromByte(0x81);
    try testing.expect(fct.err == 0x81);
}

test "FunctionCodeType.fromError" {
    var fct = FunctionCodeType.fromError(0x81);
    try testing.expect(fct.common == FunctionCode.read_coils);
    // passing a non-error code should just parse the function code
    fct = FunctionCodeType.fromError(1);
    try testing.expect(fct.common == FunctionCode.read_coils);
}

test "Type Sizes" {
    const std = @import("std");
    const slice = struct {
        s: []u8,
    };
    std.debug.print("slice: {}\n", .{@sizeOf(slice)});
    // std.debug.print("ModbusEndian: {}\n", .{@sizeOf(ModbusEndian)});
    std.debug.print("usize: {}\n", .{@sizeOf(usize)});
    std.debug.print("FunctionCode: {}\n", .{@sizeOf(FunctionCode)});
    std.debug.print("FunctionCodeType: {}\n", .{@sizeOf(FunctionCodeType)});
    std.debug.print("ExceptionCode: {}\n", .{@sizeOf(ExceptionCode)});
    std.debug.print("ExceptionCodeType: {}\n", .{@sizeOf(ExceptionCodeType)});
    std.debug.print("ProtocolDataUnit: {}\n", .{@sizeOf(ProtocolDataUnit)});
    std.debug.print("TcpHeader: {}\n", .{@sizeOf(TcpHeader)});
    std.debug.print("TcpAppDataUnit: {}\n", .{@sizeOf(TcpAppDataUnit)});
    std.debug.print("SerialHeader: {}\n", .{@sizeOf(SerialHeader)});
    std.debug.print("SerialAppDataUnit: {}\n", .{@sizeOf(SerialAppDataUnit)});
    std.debug.print("Request: {}\n", .{@sizeOf(Request)});
    std.debug.print("ErrorResponse: {}\n", .{@sizeOf(ErrorResponse)});
}

const testing = @import("std").testing;
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
            => 43,
        };
    }
};

test "FunctionCode.getCode" {
    const can = FunctionCode.canopen_general_reference;
    try testing.expect(43 == can.getCode());
    try testing.expect(3 == FunctionCode.read_holding_register.getCode());
}

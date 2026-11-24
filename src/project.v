
`default_nettype none

module tt_um_ALU4b (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,

    input  wire ena,
    input  wire clk,
    input  wire rst_n
);

    // Operation codes
    localparam ADD = 4'b0000;
    localparam SUB = 4'b0001;
    localparam MUL = 4'b0010;
    localparam DIV = 4'b0011;
    localparam AND_OP = 4'b0100;
    localparam OR_OP  = 4'b0101;
    localparam XOR_OP = 4'b0110;
    localparam NOT_OP = 4'b0111;
    localparam ENC = 4'b1000;

    // Inputs
    wire [3:0] a = ui_in[7:4];
    wire [3:0] b = ui_in[3:0];

    // Operation selector
    wire [3:0] opcode = uio_in[3:0];

    // Encryption key
    localparam [7:0] ENCRYPTION_KEY = 8'hAB;

    // Arithmetic results
    wire [4:0] add_result;
    wire [4:0] sub_result;
    wire [7:0] mul_result;

    wire [3:0] div_quotient;
    wire [3:0] div_remainder;

    // Logic results
    wire [3:0] and_result = a & b;
    wire [3:0] or_result  = a | b;
    wire [3:0] xor_result = a ^ b;
    wire [3:0] not_result = ~a;

    // Arithmetic operations
    assign add_result = {1'b0, a} + {1'b0, b};
    assign sub_result = {1'b0, a} - {1'b0, b};

    assign mul_result = a * b;

    assign div_quotient =
        (b != 4'b0000) ? a / b : 4'b0000;

    assign div_remainder =
        (b != 4'b0000) ? a % b : 4'b0000;

    // Registers
    reg [7:0] result;
    reg carry_out;
    reg overflow;

    // Sequential ALU
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            result <= 8'b00000000;
            carry_out <= 1'b0;
            overflow <= 1'b0;
        end

        else begin

            // Default flags
            carry_out <= 1'b0;
            overflow <= 1'b0;

            case (opcode)

                // ADDITION
                ADD: begin
                    result <= {4'b0000, add_result[3:0]};
                    carry_out <= add_result[4];

                    overflow <=
                        (~(a[3] ^ b[3])) &
                        (a[3] ^ add_result[3]);
                end

                // SUBTRACTION
                SUB: begin
                    result <= {4'b0000, sub_result[3:0]};

                    // Carry indicates no borrow
                    carry_out <= ~sub_result[4];

                    overflow <=
                        (a[3] ^ b[3]) &
                        (a[3] ^ sub_result[3]);
                end

                // MULTIPLICATION
                MUL: begin
                    result <= mul_result;
                end

                // DIVISION
                DIV: begin
                    // Upper nibble = quotient
                    // Lower nibble = remainder
                    result <= {div_quotient, div_remainder};
                end

                // AND
                AND_OP: begin
                    result <= {4'b0000, and_result};
                end

                // OR
                OR_OP: begin
                    result <= {4'b0000, or_result};
                end

                // XOR
                XOR_OP: begin
                    result <= {4'b0000, xor_result};
                end

                // NOT A
                NOT_OP: begin
                    result <= {4'b0000, not_result};
                end

                // ENCRYPTION
                ENC: begin
                    result <= {a, b} ^ ENCRYPTION_KEY;
                end

                // INVALID OPCODE
                default: begin
                    result <= 8'b00000000;
                end

            endcase
        end
    end

    // Main outputs
    assign uo_out = result;

    // Bidirectional output data
    assign uio_out = {
        overflow,   // uio[7]
        carry_out,  // uio[6]
        6'b000000
    };

    // Output enable
    // uio[7] and uio[6] are outputs.
    // uio[5:0] are inputs.
    assign uio_oe = 8'b11000000;

    // Unused signals
    wire _unused = &{ena, 1'b0};

endmodule

`default_nettype wire

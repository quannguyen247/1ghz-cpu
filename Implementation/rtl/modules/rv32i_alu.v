`timescale 1ns / 1ps
`include "cpu_defs.vh"

module rv32i_alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] op,
    output reg [31:0] out,
    output wire zero
);

    assign zero = (out == 32'd0);

    always @(*) begin
        out = 32'd0;
        case (op)
            `ALU_ADD:  out = a + b;
            `ALU_SUB:  out = a - b;
            `ALU_SLL:  out = a << b[4:0];
            `ALU_SLT:  out = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLTU: out = (a < b) ? 32'd1 : 32'd0;
            `ALU_XOR:  out = a ^ b;
            `ALU_SRL:  out = a >> b[4:0];
            `ALU_SRA:  out = $signed(a) >>> b[4:0];
            `ALU_OR:   out = a | b;
            `ALU_AND:  out = a & b;
            default:   out = 32'd0;
        endcase
    end

endmodule

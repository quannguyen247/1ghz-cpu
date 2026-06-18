`timescale 1ns / 1ps

module rv32i_ctrl (
    input wire [4:0] rs1_id,
    input wire [4:0] rs2_id,
    input wire [4:0] rs1_ex,
    input wire [4:0] rs2_ex,
    input wire [4:0] rd_ex,
    input wire [4:0] rd_mem,
    input wire [4:0] rd_wb,
    input wire reg_write_mem,
    input wire reg_write_wb,
    input wire mem_read_ex,
    input wire branch_taken_ex,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b,
    output reg stall,
    output reg flush
);

    always @(*) begin
        forward_a = 2'b00;
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex)) begin
            forward_a = 2'b10;
        end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex)) begin
            forward_a = 2'b01;
        end
    end

    always @(*) begin
        forward_b = 2'b00;
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex)) begin
            forward_b = 2'b10;
        end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex)) begin
            forward_b = 2'b01;
        end
    end

    always @(*) begin
        stall = 1'b0;
        if (mem_read_ex && (rd_ex != 5'd0) && ((rd_ex == rs1_id) || (rd_ex == rs2_id))) begin
            stall = 1'b1;
        end
    end

    always @(*) begin
        flush = branch_taken_ex;
    end

endmodule

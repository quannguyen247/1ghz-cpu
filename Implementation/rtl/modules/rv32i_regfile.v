`timescale 1ns / 1ps

module rv32i_regfile (
    input wire clk,
    input wire rst_n,
    input wire [4:0] rs1,
    input wire [4:0] rs2,
    input wire [4:0] rd,
    input wire [31:0] wdata,
    input wire reg_write,
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data
);

    reg [31:0] rf [0:31];
    integer i;

    always @(*) begin
        if (rs1 == 5'd0) begin
            rs1_data = 32'd0;
        end else if (reg_write && (rd == rs1)) begin
            rs1_data = wdata;
        end else begin
            rs1_data = rf[rs1];
        end
    end

    always @(*) begin
        if (rs2 == 5'd0) begin
            rs2_data = 32'd0;
        end else if (reg_write && (rd == rs2)) begin
            rs2_data = wdata;
        end else begin
            rs2_data = rf[rs2];
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'd0;
            end
        end else begin
            if (reg_write && (rd != 5'd0)) begin
                rf[rd] <= wdata;
            end
        end
    end

endmodule

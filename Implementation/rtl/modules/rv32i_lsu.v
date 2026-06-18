`timescale 1ns / 1ps
`include "cpu_defs.vh"

module rv32i_lsu (
    input wire [31:0] addr,
    input wire [31:0] wdata_in,
    input wire mem_write,
    input wire mem_read,
    input wire [2:0] funct3,
    input wire [31:0] dmem_rdata,
    output wire [31:0] dmem_addr,
    output reg [31:0] dmem_wdata,
    output wire dmem_we,
    output reg [3:0] dmem_sel,
    output reg [31:0] rdata_out
);

    assign dmem_addr = {addr[31:2], 2'b00};
    assign dmem_we = mem_write;

    always @(*) begin
        dmem_sel = 4'b0000;
        dmem_wdata = wdata_in;
        if (mem_write) begin
            case (funct3)
                3'b000: begin
                    case (addr[1:0])
                        2'b00: begin
                            dmem_sel = 4'b0001;
                            dmem_wdata = {24'b0, wdata_in[7:0]};
                        end
                        2'b01: begin
                            dmem_sel = 4'b0010;
                            dmem_wdata = {16'b0, wdata_in[7:0], 8'b0};
                        end
                        2'b10: begin
                            dmem_sel = 4'b0100;
                            dmem_wdata = {8'b0, wdata_in[7:0], 16'b0};
                        end
                        2'b11: begin
                            dmem_sel = 4'b1000;
                            dmem_wdata = {wdata_in[7:0], 24'b0};
                        end
                    endcase
                end
                3'b001: begin
                    if (addr[1]) begin
                        dmem_sel = 4'b1100;
                        dmem_wdata = {wdata_in[15:0], 16'b0};
                    end else begin
                        dmem_sel = 4'b0011;
                        dmem_wdata = {16'b0, wdata_in[15:0]};
                    end
                end
                3'b010: begin
                    dmem_sel = 4'b1111;
                    dmem_wdata = wdata_in;
                end
                default: begin
                    dmem_sel = 4'b0000;
                    dmem_wdata = wdata_in;
                end
            endcase
        end
    end

    reg [31:0] shifted_rdata;

    always @(*) begin
        rdata_out = 32'd0;
        case (funct3)
            `LD_LB: begin
                shifted_rdata = dmem_rdata >> (addr[1:0] * 8);
                rdata_out = {{24{shifted_rdata[7]}}, shifted_rdata[7:0]};
            end
            `LD_LH: begin
                shifted_rdata = dmem_rdata >> (addr[1] * 16);
                rdata_out = {{16{shifted_rdata[15]}}, shifted_rdata[15:0]};
            end
            `LD_LW: begin
                rdata_out = dmem_rdata;
            end
            `LD_LBU: begin
                shifted_rdata = dmem_rdata >> (addr[1:0] * 8);
                rdata_out = {24'b0, shifted_rdata[7:0]};
            end
            `LD_LHU: begin
                shifted_rdata = dmem_rdata >> (addr[1] * 16);
                rdata_out = {16'b0, shifted_rdata[15:0]};
            end
            default: begin
                rdata_out = dmem_rdata;
            end
        endcase
    end

endmodule

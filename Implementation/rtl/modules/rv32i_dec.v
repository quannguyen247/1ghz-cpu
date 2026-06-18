`timescale 1ns / 1ps
`include "cpu_defs.vh"

module rv32i_dec (
    input wire [31:0] instr,
    output wire [4:0] rs1,
    output wire [4:0] rs2,
    output wire [4:0] rd,
    output reg [31:0] imm,
    output reg [3:0] alu_op,
    output reg alu_src_a,
    output reg alu_src_b,
    output reg reg_write,
    output reg mem_write,
    output reg mem_read,
    output reg mem_to_reg,
    output reg is_branch,
    output reg is_jal,
    output reg is_jalr
);

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd = instr[11:7];

    always @(*) begin
        imm = 32'd0;
        case (opcode)
            `OP_I, `OP_LOAD, `OP_JALR: imm = {{20{instr[31]}}, instr[31:20]};
            `OP_STORE: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            `OP_BRANCH: imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            `OP_LUI, `OP_AUIPC: imm = {instr[31:12], 12'b0};
            `OP_JAL: imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm = 32'd0;
        endcase
    end

    always @(*) begin
        alu_op = `ALU_ADD;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        reg_write = 1'b0;
        mem_write = 1'b0;
        mem_read = 1'b0;
        mem_to_reg = 1'b0;
        is_branch = 1'b0;
        is_jal = 1'b0;
        is_jalr = 1'b0;

        case (opcode)
            `OP_R: begin
                reg_write = 1'b1;
                case (funct3)
                    3'b000: alu_op = (funct7[5]) ? `ALU_SUB : `ALU_ADD;
                    3'b001: alu_op = `ALU_SLL;
                    3'b010: alu_op = `ALU_SLT;
                    3'b011: alu_op = `ALU_SLTU;
                    3'b100: alu_op = `ALU_XOR;
                    3'b101: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                    3'b110: alu_op = `ALU_OR;
                    3'b111: alu_op = `ALU_AND;
                    default: alu_op = `ALU_ADD;
                endcase
            end

            `OP_I: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                case (funct3)
                    3'b000: alu_op = `ALU_ADD;
                    3'b001: alu_op = `ALU_SLL;
                    3'b010: alu_op = `ALU_SLT;
                    3'b011: alu_op = `ALU_SLTU;
                    3'b100: alu_op = `ALU_XOR;
                    3'b101: alu_op = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                    3'b110: alu_op = `ALU_OR;
                    3'b111: alu_op = `ALU_AND;
                    default: alu_op = `ALU_ADD;
                endcase
            end

            `OP_LOAD: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op = `ALU_ADD;
                mem_read = 1'b1;
                mem_to_reg = 1'b1;
            end

            `OP_STORE: begin
                alu_src_b = 1'b1;
                alu_op = `ALU_ADD;
                mem_write = 1'b1;
            end

            `OP_BRANCH: begin
                alu_src_b = 1'b0;
                alu_op = `ALU_SUB;
                is_branch = 1'b1;
            end

            `OP_LUI: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op = `ALU_ADD;
            end

            `OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                alu_op = `ALU_ADD;
            end

            `OP_JAL: begin
                reg_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                alu_op = `ALU_ADD;
                is_jal = 1'b1;
            end

            `OP_JALR: begin
                reg_write = 1'b1;
                alu_src_a = 1'b0;
                alu_src_b = 1'b1;
                alu_op = `ALU_ADD;
                is_jalr = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule

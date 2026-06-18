`timescale 1ns / 1ps
`include "cpu_defs.vh"

module rv32i_cpu (
    input wire clk,
    input wire rst_n,
    output wire [31:0] imem_addr,
    input wire [31:0] imem_rdata,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input wire [31:0] dmem_rdata,
    output wire dmem_we,
    output wire [3:0] dmem_sel
);

    reg [31:0] pc;
    reg [31:0] next_pc;
    wire pc_we;

    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;
    wire if_id_we;

    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [31:0] imm;
    wire [3:0] alu_op;
    wire alu_src_a;
    wire alu_src_b;
    wire reg_write;
    wire mem_write;
    wire mem_read;
    wire mem_to_reg;
    wire is_branch;
    wire is_jal;
    wire is_jalr;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;
    reg [31:0] id_ex_imm;
    reg [4:0] id_ex_rs1;
    reg [4:0] id_ex_rs2;
    reg [4:0] id_ex_rd;
    reg [3:0] id_ex_alu_op;
    reg id_ex_alu_src_a;
    reg id_ex_alu_src_b;
    reg id_ex_reg_write;
    reg id_ex_mem_write;
    reg id_ex_mem_read;
    reg id_ex_mem_to_reg;
    reg id_ex_is_branch;
    reg id_ex_is_jal;
    reg id_ex_is_jalr;
    reg [2:0] id_ex_funct3;

    reg [1:0] op_a_sel;
    reg [1:0] op_b_sel;
    reg [31:0] op_a_fwd;
    reg [31:0] op_b_fwd;
    reg [31:0] alu_in_a;
    reg [31:0] alu_in_b;
    wire [31:0] alu_out;
    wire alu_zero;

    wire [31:0] ex_alu_out_final;
    reg [31:0] branch_target;
    reg branch_taken;

    reg [31:0] mem_alu_out;
    reg [31:0] mem_rs2_data;
    reg [4:0] mem_rd;
    reg [2:0] mem_funct3;
    reg mem_reg_write;
    reg mem_mem_write;
    reg mem_mem_read;
    reg mem_mem_to_reg;

    wire [31:0] lsu_rdata;

    reg [31:0] wb_alu_out;
    reg [31:0] wb_lsu_rdata;
    reg [4:0] wb_rd;
    reg wb_reg_write;
    reg wb_mem_to_reg;

    wire [31:0] wb_wdata;

    wire [1:0] forward_a_ctrl;
    wire [1:0] forward_b_ctrl;
    wire stall_ctrl;
    wire flush_ctrl;

    assign imem_addr = pc;
    assign pc_we = !stall_ctrl;
    assign if_id_we = !stall_ctrl;

    always @(*) begin
        if (branch_taken) begin
            next_pc = branch_target;
        end else begin
            next_pc = pc + 32'd4;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            pc <= 32'h00000000;
        end else if (pc_we) begin
            pc <= next_pc;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            if_id_pc <= 32'd0;
            if_id_instr <= 32'h00000013;
        end else if (flush_ctrl) begin
            if_id_pc <= 32'd0;
            if_id_instr <= 32'h00000013;
        end else if (if_id_we) begin
            if_id_pc <= pc;
            if_id_instr <= imem_rdata;
        end
    end

    rv32i_dec u_dec (
        .instr(if_id_instr),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm(imm),
        .alu_op(alu_op),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .is_branch(is_branch),
        .is_jal(is_jal),
        .is_jalr(is_jalr)
    );

    rv32i_regfile u_rf (
        .clk(clk),
        .rst_n(rst_n),
        .rs1(rs1),
        .rs2(rs2),
        .rd(wb_rd),
        .wdata(wb_wdata),
        .reg_write(wb_reg_write),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    always @(posedge clk) begin
        if (!rst_n || flush_ctrl || stall_ctrl) begin
            id_ex_pc <= 32'd0;
            id_ex_rs1_data <= 32'd0;
            id_ex_rs2_data <= 32'd0;
            id_ex_imm <= 32'd0;
            id_ex_rs1 <= 5'd0;
            id_ex_rs2 <= 5'd0;
            id_ex_rd <= 5'd0;
            id_ex_alu_op <= 4'd0;
            id_ex_alu_src_a <= 1'b0;
            id_ex_alu_src_b <= 1'b0;
            id_ex_reg_write <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_is_branch <= 1'b0;
            id_ex_is_jal <= 1'b0;
            id_ex_is_jalr <= 1'b0;
            id_ex_funct3 <= 3'd0;
        end else begin
            id_ex_pc <= if_id_pc;
            id_ex_rs1_data <= rs1_data;
            id_ex_rs2_data <= rs2_data;
            id_ex_imm <= imm;
            id_ex_rs1 <= rs1;
            id_ex_rs2 <= rs2;
            id_ex_rd <= rd;
            id_ex_alu_op <= alu_op;
            id_ex_alu_src_a <= alu_src_a;
            id_ex_alu_src_b <= alu_src_b;
            id_ex_reg_write <= reg_write;
            id_ex_mem_write <= mem_write;
            id_ex_mem_read <= mem_read;
            id_ex_mem_to_reg <= mem_to_reg;
            id_ex_is_branch <= is_branch;
            id_ex_is_jal <= is_jal;
            id_ex_is_jalr <= is_jalr;
            id_ex_funct3 <= if_id_instr[14:12];
        end
    end

    always @(*) begin
        case (forward_a_ctrl)
            2'b10:   op_a_fwd = mem_alu_out;
            2'b01:   op_a_fwd = wb_wdata;
            default: op_a_fwd = id_ex_rs1_data;
        endcase
    end

    always @(*) begin
        case (forward_b_ctrl)
            2'b10:   op_b_fwd = mem_alu_out;
            2'b01:   op_b_fwd = wb_wdata;
            default: op_b_fwd = id_ex_rs2_data;
        endcase
    end

    always @(*) begin
        alu_in_a = (id_ex_alu_src_a) ? id_ex_pc : op_a_fwd;
        alu_in_b = (id_ex_alu_src_b) ? id_ex_imm : op_b_fwd;
    end

    rv32i_alu u_alu (
        .a(alu_in_a),
        .b(alu_in_b),
        .op(id_ex_alu_op),
        .out(alu_out),
        .zero(alu_zero)
    );

    assign ex_alu_out_final = (id_ex_is_jal || id_ex_is_jalr) ? (id_ex_pc + 32'd4) : alu_out;

    always @(*) begin
        if (id_ex_is_jalr) begin
            branch_target = (op_a_fwd + id_ex_imm) & 32'hFFFFFFFE;
        end else begin
            branch_target = id_ex_pc + id_ex_imm;
        end
    end

    always @(*) begin
        branch_taken = 1'b0;
        if (id_ex_is_jal || id_ex_is_jalr) begin
            branch_taken = 1'b1;
        end else if (id_ex_is_branch) begin
            case (id_ex_funct3)
                `BR_BEQ:  branch_taken = alu_zero;
                `BR_BNE:  branch_taken = !alu_zero;
                `BR_BLT:  branch_taken = ($signed(op_a_fwd) < $signed(op_b_fwd));
                `BR_BGE:  branch_taken = ($signed(op_a_fwd) >= $signed(op_b_fwd));
                `BR_BLTU: branch_taken = (op_a_fwd < op_b_fwd);
                `BR_BGEU: branch_taken = (op_a_fwd >= op_b_fwd);
                default:  branch_taken = 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            mem_alu_out <= 32'd0;
            mem_rs2_data <= 32'd0;
            mem_rd <= 5'd0;
            mem_funct3 <= 3'd0;
            mem_reg_write <= 1'b0;
            mem_mem_write <= 1'b0;
            mem_mem_read <= 1'b0;
            mem_mem_to_reg <= 1'b0;
        end else begin
            mem_alu_out <= ex_alu_out_final;
            mem_rs2_data <= op_b_fwd;
            mem_rd <= id_ex_rd;
            mem_funct3 <= id_ex_funct3;
            mem_reg_write <= id_ex_reg_write;
            mem_mem_write <= id_ex_mem_write;
            mem_mem_read <= id_ex_mem_read;
            mem_mem_to_reg <= id_ex_mem_to_reg;
        end
    end

    rv32i_lsu u_lsu (
        .addr(mem_alu_out),
        .wdata_in(mem_rs2_data),
        .mem_write(mem_mem_write),
        .mem_read(mem_mem_read),
        .funct3(mem_funct3),
        .dmem_rdata(dmem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_sel(dmem_sel),
        .rdata_out(lsu_rdata)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            wb_alu_out <= 32'd0;
            wb_lsu_rdata <= 32'd0;
            wb_rd <= 5'd0;
            wb_reg_write <= 1'b0;
            wb_mem_to_reg <= 1'b0;
        end else begin
            wb_alu_out <= mem_alu_out;
            wb_lsu_rdata <= lsu_rdata;
            wb_rd <= mem_rd;
            wb_reg_write <= mem_reg_write;
            wb_mem_to_reg <= mem_mem_to_reg;
        end
    end

    assign wb_wdata = (wb_mem_to_reg) ? wb_lsu_rdata : wb_alu_out;

    rv32i_ctrl u_ctrl (
        .rs1_id(rs1),
        .rs2_id(rs2),
        .rs1_ex(id_ex_rs1),
        .rs2_ex(id_ex_rs2),
        .rd_ex(id_ex_rd),
        .rd_mem(mem_rd),
        .rd_wb(wb_rd),
        .reg_write_mem(mem_reg_write),
        .reg_write_wb(wb_reg_write),
        .mem_read_ex(id_ex_mem_read),
        .branch_taken_ex(branch_taken),
        .forward_a(forward_a_ctrl),
        .forward_b(forward_b_ctrl),
        .stall(stall_ctrl),
        .flush(flush_ctrl)
    );

endmodule

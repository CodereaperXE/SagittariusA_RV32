// 9/7/25 rb
`include "register.v"
`include "alu.v"
`include "mux.v"
`include "memory_controller_tb.v"
`include "sign_extend.v"
`include "register_file.v"

module cpu_module(
    input wire pc_enable,
    input wire clk,
    input wire memsel_mux_select,
    input wire mem_write_enable,
    output wire mem_op_r,
    input wire ir_reg_enable,
    output wire [31:0] ir_reg_out,
    input wire rf_we,
    input wire [1:0] regfile_mux_select,
    input wire [3:0] imm_src,
    input wire [1:0] opsel1_select,
    input wire [1:0] opsel2_select,
    output wire zero,
    input wire [3:0] alu_sel,
    input wire alu_reg_enable,   
    input wire alu_reg_mux_select,
    input wire reset,
    input wire mem_enable,
    input wire old_pc_enable,
    input wire mem_reg_enable,
    input wire [1:0] instr_mode,
    output wire negative
    );

// wire pc_enable;
wire [31:0] pc_out;

// reg clk;
reg global_we=1;

//pc
register_module #(.n(32)) pc(
    .in(alu_reg_mux_out),
    .clk(clk),
    .we(pc_enable),
    .out(pc_out),
    .reset(reset)
    );

// wire old_pc_enable;
wire [31:0] old_pc_out;
//old pc
register_module #(.n(32)) old_pc(
    .in(pc_out),
    .clk(clk),
    .we(old_pc_enable),
    .out(old_pc_out),
    .reset(reset)
    );

// wire memsel_mux_select;
wire [31:0] memsel_mux_out;
//memsel mux
assign memsel_mux_out = (memsel_mux_select==1'b1) ? alu_reg_mux_out : pc_out;

// wire mem_write_enable;
wire [31:0] mem_data_out;
// wire mem_op_r;

//wire mem_enable
//memory module
memory_controller_module memory(
    .addr(memsel_mux_out[23:0]),
    .we(mem_write_enable),
    .clk(clk),
    .data_in(rf_reg_rs2_out),
    .data_out(mem_data_out),
    .op_r(mem_op_r),
    .enable(mem_enable),
    .instr_mode(instr_mode)
    );


//ir register
// wire ir_reg_enable;
// wire [31:0] ir_reg_out; //main decoding line
register_module ir_reg(
    .in(mem_data_out),
    .clk(clk),
    .we(ir_reg_enable),
    .out(ir_reg_out),
    .reset(reset)
    );

// wire mem_reg_enable;
wire [31:0] mem_reg_out;
//register to read data from sb operations
register_module mem_read_reg(
    .in(mem_data_out),
    .clk(clk),
    .we(mem_reg_enable),
    .out(mem_reg_out),
    .reset(reset)
    );


// wire rf_we;
//regfile mux
// wire regfile_mux_select;
wire [31:0] regfile_mux_out;
assign regfile_mux_out = (regfile_mux_select==2'b00) ? mem_data_out :
                         (regfile_mux_select==2'b01) ? alu_reg_mux_out :
                         (regfile_mux_select==2'b10) ? sign_extend_out :
                         mem_data_out;

wire [31:0] rs1_out;
wire [31:0] rs2_out; 

//register file
register_file_module regfile(
    .a1(ir_reg_out[19:15]),
    .a2(ir_reg_out[24:20]),
    .a3(ir_reg_out[11:7]),
    .we(rf_we),
    .wd3(regfile_mux_out), 
    .rd1(rs1_out),
    .rd2(rs2_out),
    .reset(reset),
    .clk(clk)
    );

wire [31:0] rf_reg_rs1_out;
wire [31:0] rf_reg_rs2_out;

//register file register
register_module #(.n(32)) rf_reg1(
    .in(rs1_out),
    .clk(clk),
    .we(global_we),
    .out(rf_reg_rs1_out),
    .reset(reset)
    );

register_module #(.n(32)) rf_reg2(
    .in(rs2_out),
    .clk(clk),
    .we(global_we),
    .out(rf_reg_rs2_out),
    .reset(reset)
    );


//sign extender
// wire [2:0] imm_src;
wire [31:0] sign_extend_out;
sign_extend_module sign_extend(
    .inp(ir_reg_out),
    .imm_src(imm_src),
    .out(sign_extend_out),
    // .rs2_inp(rf_reg_rs2_out), //not required
    .mem_inp(mem_reg_out)
    );

//opsel1 mux

wire [31:0] opsel1_mux_out;
// wire opsel1_select;
assign opsel1_mux_out = (opsel1_select==2'b00) ? rf_reg_rs1_out:
                        (opsel1_select==2'b01) ? pc_out:
                        (opsel1_select==2'b10) ? old_pc_out:
                        2'b00;

wire [31:0] opsel2_mux_out;
// wire [1:0] opsel2_select;

//opsel2 mux
assign opsel2_mux_out = (opsel2_select==2'b10) ? rf_reg_rs2_out:
                        (opsel2_select==2'b01) ? 32'd4 :
                        (opsel2_select==2'b00) ? sign_extend_out:
                        32'd0;


// wire zero;
// wire [3:0] alu_sel;
wire [31:0] alu_out;
alu_module alu1(
    .op1(opsel1_mux_out),
    .op2(opsel2_mux_out),
    .alu_sel(alu_sel),
    .res(alu_out),
    .zero(zero),
    .negative(negative)
    );

// wire alu_reg_enable;
wire [31:0] alu_reg_out;

//alu reg
register_module #(.n(32)) alu_reg(
    .in(alu_out),
    .clk(clk),
    .we(alu_reg_enable),
    .out(alu_reg_out),
    .reset(reset)
    );


wire [31:0] alu_reg_mux_out;
// wire alu_reg_mux_select;

//alu reg mux
assign alu_reg_mux_out = (alu_reg_mux_select==1'b1) ? alu_out : alu_reg_out;



endmodule
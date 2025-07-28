

module sign_extend_module(
	input [31:0] inp,
    // input [31:0] rs2_inp,
    input [31:0] mem_inp,
	input [3:0] imm_src,
	output wire [31:0] out
);

// immsrc
// 0000 - I
// 0001 - S
// 0010 - B
// 0011 - J
// 0100 - U
// 0101 - Unsigned imm (I type) for opcode 19
// 0110 - lb instruction specific
// 0111 - lh instruction specific
// 1000 - lbu instruction specific
// 1001 - lhu instruction specific
// 1010 - sb instruction specific
// 1011 - sh instruction specific
// 1100 - lw (second mem cycle)

assign out = (imm_src == 4'b0000) ? {{20{inp[31]}}, inp[31:20]} :
             (imm_src == 4'b0001) ? {{20{inp[31]}}, inp[31:25], inp[11:7]} :
             (imm_src == 4'b0010) ? {{20{inp[31]}}, inp[7], inp[30:25], inp[11:8], 1'b0} :
             (imm_src == 4'b0011) ? {{12{inp[31]}}, inp[19:12], inp[20], inp[30:21], 1'b0} :
             (imm_src == 4'b0100) ? {inp[31:12],12'b0} :
             (imm_src == 4'b0101) ? {inp} :
             {imm_src == 4'b0110} ? {{24{mem_inp[7]}}, mem_inp[7:0]} :
             {imm_src == 4'b0111} ? {{16{mem_inp[15]}}, mem_inp[15:0]} :
             {imm_src == 4'b1000} ? {24'b0, mem_inp[7:0]} :
             {imm_src == 4'b1001} ? {16'b0, mem_inp[15:0]} :
             // {imm_src == 4'b1010} ? {mem_inp[31:8], rs2_inp[7:0]} :
             // {imm_src == 4'b1011} ? {mem_inp[31:16], rs2_inp[15:0]} :
             {imm_src == 4'b1100} ? {mem_inp} :
             32'd0;

endmodule


module sign_extend_module(
	input [31:0] inp,
	input [2:0] imm_src,
	output wire [31:0] out
);

// immsrc
// 000 - I
// 001 - S
// 010 - B
// 011 - J
// 100 - U
assign out = (imm_src == 3'b000) ? {{20{inp[31]}}, inp[31:20]} :
             (imm_src == 3'b001) ? {{20{inp[31]}}, inp[31:25], inp[11:7]} :
             (imm_src == 3'b010) ? {{20{inp[31]}}, inp[7], inp[30:25], inp[11:8], 1'b0} :
             (imm_src == 3'b011) ? {{12{inp[31]}}, inp[19:12], inp[20], inp[30:21], 1'b0} :
             (imm_src == 3'b100) ? {inp[31:12],12'b0} :
             32'd0;

 
endmodule
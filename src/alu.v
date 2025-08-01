

module alu_module(
    input [31:0] op1,
    input [31:0] op2,
    input [3:0] alu_sel,
    output [31:0] res,
    output zero,
    output negative,
    output unegative
);

assign zero = ((op1-op2)==32'd0) ? 1 : 0;
assign negative = ((op1 - op2) & 32'h80000000) ? 1 : 0;
assign unegative = (op1 < op2) ? 1 : 0; //used for bltu and bgeu

//for arithmetic shift instructions
wire signed [31:0] s_op1 = op1;
wire signed [31:0] sra_result = s_op1 >>> op2;

assign res = (alu_sel==4'b0000) ? op1+op2 : //add or addi
             (alu_sel==4'b0001) ? op1-op2 : //sub
             (alu_sel==4'b0010) ? op2 : //send only op2 for lui
             (alu_sel==4'b0011) ? op1 << op2 : //left shift (assumming compiler takes care of selecting operand op2[4:0] in R type instructions)
             (alu_sel==4'b0100) ? op1 >> op2 : //right shift (assumming compiler takes care of selecting operand op2[4:0] in R type instructions)
             (alu_sel==4'b0101) ? sra_result : //arithmetic right shift (assumming compiler takes care of selecting operand op2[4:0] in R type instructions)
             (alu_sel==4'b0110) ? op1 ^ op2 : //xor or xori
             (alu_sel==4'b0111) ? op1 | op2 : //or or ori
             (alu_sel==4'b1000) ? op1 & op2 : //and or andi
             (alu_sel==4'b1001) ? ($signed(op1) < $signed(op2)) ? 1 : 0 : //slti or slt
             (alu_sel==4'b1010) ? ((op1 < op2) ? 1 : 0): //sltiu or sltu
             32'd0;
endmodule


// module main;

// reg [31:0] op1;
// reg [31:0] op2;
// reg [1:0] alu_sel;
// wire [31:0] res;
// wire zero;

// alu_module alu(.op1(op1),.op2(op2),.alu_sel(alu_sel),.res(res),.zero(zero));

// initial begin
//     $display("op1\t\t\t\t\t op2\t\t\t\t\t res\t\t\t\t\t zero");
//     $monitor("%b\t%b\t%b\t%b",op1,op2,res,zero);
//         alu_sel=2'b00;op1=32'd6;op2=32'd5; #10;

//     $finish;

// end


// endmodule
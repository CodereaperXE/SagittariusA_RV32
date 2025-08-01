

module alu_module(
    input [31:0] op1,
    input [31:0] op2,
    input [3:0] alu_sel,
    output [31:0] res,
    output zero,
    output negative
);

assign zero = ((op1-op2)==32'd0) ? 1 : 0;
assign negative = (op1-op2) [31]; 

reg sign=0;

assign res = (alu_sel==4'b0000) ? op1+op2 :
             (alu_sel==4'b0001) ? op1-op2 : 
             (alu_sel==4'b0010) ? op2 : //send only op2 for lui
             (alu_sel==4'b0011) ? op1 << op2 : //left shift
             (alu_sel==4'b0100) ? op1 >> op2 : //right shift
             (alu_sel==4'b0101) ? $signed(op1) >>> op2 : //arithmetic right shift
             (alu_sel==4'b0110) ? op1 ^ op2 : //xor
             (alu_sel==4'b0111) ? op1 | op2 : //or
             (alu_sel==4'b1000) ? op1 & op2 : //and
             (alu_sel==4'b1001) ? ($signed(op1) < $signed(op2)) ? 1 : 0 : //slti
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
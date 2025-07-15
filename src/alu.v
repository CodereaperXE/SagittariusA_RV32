

module alu_module(
    input [31:0] op1,
    input [31:0] op2,
    input [2:0] alu_sel,
    output [31:0] res,
    output zero
);

assign zero = (op1 == op2);


assign res = (alu_sel==3'b000) ? op1+op2 :
             (alu_sel==3'b001) ? op1-op2 : 
             (alu_sel==3'b010) ? op2 : //send only op2
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
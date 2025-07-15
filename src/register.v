

module register_module #(parameter n=32)(
    input [n-1:0] in,
    input clk,
    input we,
    output [n-1:0] out,
    input reset
);

reg [n-1:0] register;

assign out = register;

always@(posedge clk or posedge reset) begin
    if(reset) begin
        register <= {n{1'b0}};
    end
    else
    if(we == 1'b1) begin
        register <= in;
    end
end




endmodule


// module main;

// reg [1:0] in;
// reg clk;
// reg we;
// wire [1:0] out;
// register_module register(.in(in),.clk(clk),.we(we),.out(out));
// initial begin
//     $display("in clk we out");
//     $monitor("%b %b %b\t %b",in,clk,we,out);
//         we=1;
//         clk=0; in=0; #10;
//         clk=1; #10;
//         clk=0; in=1; #10;
//         clk=1; #10;
//         clk=0; in=2; #10;
//         clk=1; #10;


//     $finish;
// end
// endmodule
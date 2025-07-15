

module mux_module #(parameter n = 2, parameter WIDTH = 32)(
    input  wire [n-1:0] select,
    input  wire [(1<<n)*WIDTH-1:0] inp,  // Packed input vector
    output wire [WIDTH-1:0] out
);

    assign out = inp[select*WIDTH +: WIDTH];

endmodule



// module main;

// reg [1:0] select;
// reg [3:0] inp;
// output out;

// mux_module #(.n(2)) mux (.select(select),.inp(inp),.out(out));

// initial begin;
//     $display("select\t inp\t out");
//     $monitor("%b\t%b\t%b\t",select,inp,out);
//         inp = 4'b1010; select=2'b00; #10;
//         select=2'b11;#10;
//     $finish;
// end
// endmodule




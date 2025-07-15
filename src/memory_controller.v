

// module memory_controller(
//     output [3:0] address,
//     input clk,
//     output [3:0] data
// );

module memory_controller_module(
    input [23:0] addr,              // address 
    input we,                       // write enable
    input clk,                      // clk
    input [31:0] data_in,           // data in
    output wire [31:0] data_out,    // data out
    output op_r                     // output data ready
);


reg [3:0] counter=4'd0; //temporary to waste cycles simulating real case
reg [23:0] mem [7:0];

//just for the testbench purpose not synthesizable
always@(*) begin
    mem[24'd4]=32'hf0f0f0f0;
end

assign data_out = (!we && counter==4'd3) ? mem[addr] : 32'd0;

always@(posedge clk) begin
     

    if(counter==4'd4) begin
        counter <= 4'd0;
        op_r <=0;
    end

    else
        counter <=counter+1;

    if(counter==4'd3) begin
        if(we)
            mem[addr] <= data_in;

        op_r <=1;
    end

end
endmodule

//testbench

`timescale 1 ns / 10 ps

module main();
    reg clk=0;
    reg [23:0] addr=24'd4;              // address 
    reg we;                       // write enable
    reg clk;                      // clk
    reg [31:0] data_in;           // data in
    wire [31:0] data_out;    // data out
    wire op_r;

    reg [31:0] storage=32'd0;

    parameter duration = 10000;

    memory_controller_module uut(.clk(clk),.addr(addr),.we(we),.data_in(data_in),.data_out(data_out),.op_r(op_r));

    always(posedge clk) begin
        if(op_r)
            storage <= data_out;
    end


    always begin
        #41.667
        clk = ~clk;
    end

    initial begin
        $dumpfile("memory_controller_tb.vcd");
        $dumpvars(0,main);

        #(duration)

        $display("finished");
        $finish();
    end
endmodule;





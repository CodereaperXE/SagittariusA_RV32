

module register_file_module (
    input [4:0] a1,
    input [4:0] a2,
    input [4:0] a3,
    input [31:0] wd3,
    input we,
    input clk,
    input reset,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

reg [31:0] registers [0:31];


assign rd1 = registers[a1];
assign rd2 = registers[a2];

integer i;

always@(posedge clk or posedge reset) begin
    if(reset) begin

        // for(i=0;i<32;i++) //testbench //sw
            // if(i==2)
            //     registers[i] <= 32'h00008000;
            // else if(i==3)
            //     // registers[i] <= 32'haabbccdd;
            //     registers[i] <= 32'h00008000;
            // else
            //     registers[i] <= 32'd0;

        // for(i=0;i<32;i++) //testbench beq
        //     if(i==4)
        //         registers[i] <= 32'h00008000;
        //     else if(i==5)
        //         registers[i] <= 32'd5423;
        //     else
        //         registers[i] <= 32'd0;

        // for(i=0;i<32;i++) //testbench jalr
        //     if(i==2)
        //         registers[i] <= 32'h00008000;
        //     else
        //         registers[i] <= 32'd0;

        // for(i=0;i<32;i++) //testbench jalr
        //     if(i==2)
        //         registers[i] <= 32'd10;
            
        //     else
        //         registers[i] <= 32'd0;

        // for(i=0;i<32;i++) //slli x2, x3, 3
        //     if(i==3)
        //         registers[i]<=32'd1;
        //     else registers[i] <=32'd0;

        // for(i=0;i<32;i++) //slti x1, x3, 2 
        //     if(i==3)
        //         registers[i]<=32'd5;
        //     else registers[i] <=32'd0;
        

        // for(i=0;i<32;i++) //ori x1, x3, -1524 (1010 0000 1100) 2572
        //     if(i==3)
        //         registers[i]<=32'd1427; //(0101 1001 0011)
        //     else registers[i] <=32'd0;

        for(i=0;i<32;i++) //bltu x1, x2, 16 0020e863
        if(i==1)
            registers[i]<=32'd12; 
        else if(i==2)
            registers[i]<=32'd13;
        
        else registers[i] <=32'd0;
    end
    if(we && (a3 != 5'd0)) begin
        registers[a3] <= wd3;
    end
end


endmodule


// module main;

// reg [4:0] a1;
// reg [4:0] a2;
// reg [4:0] a3;
// reg [31:0] wd3;
// reg we;
// reg clk;
// wire [31:0] rd1;
// wire [31:0] rd2;


// register_file_module register_file(.a1(a1),.a2(a2),.a3(a3),.wd3(wd3),.we(we),.clk(clk),.rd1(rd1),.rd2(rd2));

// initial begin;
//     $display("a1\ta2\ta3\trd1\t\t\t\t\trd2");
//     $monitor("%b\t%b\t%b\t%b\t%b",a1,a2,a3,rd1,rd2);
//     a3=5'd9;wd3=32'b1000;we=1;clk=1; #10;
//     clk=0;we=0; #10;
//     a1=5'd9; #10;
//     $finish;
// end


// endmodule



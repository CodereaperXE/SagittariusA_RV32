

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
    output wire op_r,               // output data ready
    input enable,                   // start the r/w
    input [1:0] instr_mode          //instruction mode
);

reg [23:0] addr_reg=32'd0;
reg [3:0] counter=4'd0; //temporary to waste cycles simulating real case
reg [7:0] mem [0:80]; //byte address memory
reg op_rr=0;
assign op_r = op_rr;
reg state=0;
//just for the testbench purpose not synthesizable
initial begin
    mem[24'd0>>2]=32'h01008303; //lb
    mem[24'd4>>2]=32'h01009303; //lw
    mem[24'd16>>2]=32'heeeeeeee; //data
    // mem[24'd0]=32'h0064a423; //store
    // mem[24'h00000c] = 32'h01020304;
    // mem[24'd0]=32'hfe420ae3; //beq
    // mem[24'd0]=32'h0080016f; //jal
    // mem[24'd0]=32'h004100e7; //jalr

    //addi testbench
    // mem[24'd0]=32'h00c10093; 
    // mem[24'd4]=32'h00408113;
end




reg [31:0] d_out=32'd0;
assign data_out = d_out;

always@(*) begin
    if(!we && counter==4'd4) begin
        if(mode==2'b00) begin // lw
            d_out[7:0]   = mem[addr_reg[3:0]];
            d_out[15:8]  = mem[addr_reg[3:0]+4'd1];
            d_out[23:16] = mem[addr_reg[3:0]+4'd2];
            d_out[31:24] = mem[addr_reg[3:0]+4'd3];
        end
        if(mode==2'b01) begin // lb
            d_out[7:0]   = mem[addr_reg[3:0]];
            d_out[15:8]  = 0;
            d_out[23:16] = 0;
            d_out[31:24] = 0;
        end
        if(mode==2'b10) begin // lh
            d_out[7:0]   = mem[addr_reg[3:0]];
            d_out[15:8]  = mem[addr_reg[3:0]+4'd1];
            d_out[23:16] = 0;
            d_out[31:24] = 0;
        end
    end
end

always@(posedge clk) begin
        

    if(enable) begin
        counter <= 4'd0;
        op_rr <=0;
        addr_reg <= addr;
        state<=1;
    end

    if(state)
        counter <=counter+1;

    if(counter==4'd3) begin
        if(we) begin
            if(mode==2'b00) begin //sw mode
                mem[addr_reg[3:0]]      <= data_in[7:0];
                mem[addr_reg[3:0]+4'd1] <= data_in[15:8];
                mem[addr_reg[3:0]+4'd2] <= data_in[23:16];
                mem[addr_reg[3:0]+4'd3] <= data_in[31:24];
            end
            if(mode==2'b01) begin //sb mode
                mem[addr_reg[3:0]] <= data_in[7:0];
            end
            if(mode==2'b10) begin //sh mode
                mem[addr_reg[3:0]]      <= data_in[7:0];
                mem[addr_reg[3:0]+4'd1] <= data_in[15:8];
            end
        end
        op_rr <=1;
    end

    if(counter==4'd4) begin
        counter<=0;
        state<=0;
        op_rr <=0;
    end
end
endmodule

//testbench

// `timescale 1 ns / 10 ps

// module main;
//     reg clk=0;
//     reg [23:0] addr=24'd4;              // address 
//     reg we=0;                       // write enable
//     reg [31:0] data_in=32'd0;           // data in
//     wire [31:0] data_out;    // data out
//     wire op_r;

//     reg [31:0] storage=32'd0;

//     parameter duration = 10000;

//     memory_controller_module uut(.clk(clk),.addr(addr),.we(we),.data_in(data_in),.data_out(data_out),.op_r(op_r));

//     always@(posedge clk) begin
//         if(op_r)
//             storage <= data_out;
//     end


//     always begin
//         #41.667
//         clk = ~clk;
//     end

//     initial begin
//         $dumpfile("memory_controller_tb.vcd");
//         $dumpvars(0,main);

//         #(duration)

//         $display("finished");
//         $finish();
//     end

// endmodule





//8/8/2025

`timescale 1 ns / 10 ps

module memory_controller_module(
    input [23:0] addr,              // address 
    input we,                       // write enable
    input clk,                      // clk
    input [31:0] data_in,           // data in
    output wire [31:0] data_out,    // data out
    output wire op_r,               // output data ready
    input enable,                   // start the r/w
    input [1:0] instr_mode,         //instruction mode
    //extra fpga inputs

    output reg sram_ce,             // chip enable
    output reg flash_ce,            // nor flash enable
    output reg sck,                 // spi clock
    input sram_so,                  // serial output (from psram)
    input flash_so,                 // serial output (from flash)
    output wire sram_si,            // serial input (from psram)
    output wire flash_si,           // serial input (from flash)
    input reset                     // reset
    // output [6:0] c,                 // internal counter (temporary)
    // output ledg,                    // output green led (temporary)
    // output ledr                     // output reg led   (temporary)
);

localparam IDLE = 1'b0, BUSY = 1'b1;
reg state = IDLE;
reg [6:0] counter = 7'd0;
reg [7:0] cmd = 8'd0;
reg [31:0] data = 32'd0;
reg [31:0] le_data = 32'd0;
localparam read_cmd= 8'h03, write_cmd = 8'h02;
localparam sram_mode=2'b00, nor_fash_mode=2'b01, perpheral_mode=2'b10;
localparam word_mode=2'b00, byte_mode=2'b01, half_mode=2'b10;
reg [1:0] memory_mode=0;

//little endian converted and vice versa
always@(*) begin
    if(instr_mode==word_mode) begin // word mode
        le_data[31:24]=data_in[7:0];
        le_data[23:16]=data_in[15:8];
        le_data[15:8]=data_in[23:16];
        le_data[7:0]=data_in[31:24];
    end
    if(instr_mode==byte_mode) begin //byte mode
        le_data[7:0]=data_in[7:0];
        le_data[31:24]=8'd0;
        le_data[23:16]=8'd0;
        
    end
    if(instr_mode==half_mode) begin //half word mode
        le_data[15:8]=data_in[23:16];
        le_data[7:0]=data_in[31:24];
        le_data[31:24]=8'd0;
        le_data[23:16]=8'd0;
    end

end

//output data
assign data_out = (instr_mode==2'b00) ? ({data[7:0],data[15:8],data[23:16],data[31:24]}) : //word mode
                  (instr_mode==2'b01) ? ({24'b0,data[7:0]}): //byte mode
                  (instr_mode==2'b10) ? ({16'b0,data[7:0],data[15:8]}) : 32'd0; //half mode

//writing
//sram si
assign sram_si = (memory_mode==sram_mode) ? (

                    (counter < 8) ? cmd[7-counter] : //cmd

                    (counter < 32) ? addr[31-counter] : //addr

                    (
                        (instr_mode==word_mode) ?
                        (
                            (counter < 64 && we) ? le_data[63-counter] : 1'b0
                        ) :
                        (instr_mode==byte_mode) ?
                        (
                            (counter < 56 && we) ? le_data[56-counter] : 1'b0
                        ) :
                        (instr_mode==half_mode) ?
                        (
                            (counter < 48 && we) ? le_data[48-counter] : 1'b0
                        ) : 1'b0

                        
                    )

                ) : 1'b0;

//flash si (no writing into flash)
// assign flash_si = (memory_mode==nor_fash_mode) ? (

//                     (counter < 8) ? cmd[7-counter] : //cmd

//                     (counter < 32) ? addr[31-counter] : //addr

//                     (   //data
//                         (instr_mode==f) ?
//                         (
//                             (counter < 64 && we) ? data_in[63-counter]
//                         ) 
//                         : 1'b0



//                     ) : 
//                     1'b0

//                 ) : 1'b0;




always@(posedge clk or posedge reset) begin
    if(reset || !enable) begin
        sck<=1;
        sram_ce=0;
        flash_ce=1;
        counter<=0;
        state<=IDLE;
    end
    else if(enable) begin
        //sclk logic
        if(state==BUSY)
            if(sram_ce || ~flash_ce) sck <= ~sck;
            else sck <= 0;

        //read or write control

        if(state==IDLE) begin
            cmd <= (memory_mode==sram_mode) ? ((we) ? write_cmd : read_cmd) : //since both are same for flash and sram
                   (memory_mode==nor_fash_mode) ? ((we) ? write_cmd : read_cmd) :
                   (memory_mode==perpheral_mode) ? ((we) ? 8'b0 : 8'b0) : 8'd0; 

            if(memory_mode==sram_mode) sram_ce <= 1;
            if(memory_mode==flash_ce) flash_ce <= 0;
            //add peripherals in the future

            state <= BUSY;
            sck <= 0;
        end

        //counter control

        if((sram_ce && sck==1) || (flash_ce && sck==1)) begin
            if(instr_mode==word_mode) begin
                if(counter>=7'd63) begin
                    if(memory_mode==sram_mode) sram_ce <= 0;
                    if(memory_mode==flash_ce) sram_ce <= 1;
                    counter <= 0;
                    state <= IDLE;
                end
                else counter <= counter + 1;
            end
            if(instr_mode==byte_mode) begin
                if(counter>=7'd47) begin
                    if(memory_mode==sram_mode) sram_ce <= 0;
                    if(memory_mode==flash_ce) sram_ce <= 1;
                    counter <= 0;
                    state <= IDLE;
                end
                else counter <= counter + 1;
            end
            if(instr_mode==half_mode) begin
                if(counter>=7'd55) begin
                    if(memory_mode==sram_mode) sram_ce <= 0;
                    if(memory_mode==flash_ce) sram_ce <= 1;
                    counter <= 0;
                    state <= IDLE;
                end
                else counter <= counter + 1;
            end

        end 

        //input control

        if(sck==0) begin
            if(instr_mode==word_mode) begin
                if(counter > 7'd31 && counter < 7'd64 && !we) begin
                    data[63-counter] <= (memory_mode==sram_mode) ? sram_so :
                                        (memory_mode==nor_fash_mode) ? flash_so : 1'b0;
                end
            end
            if(instr_mode==byte_mode) begin
                if(counter > 7'd31 && counter < 7'd48 && !we) begin
                    data[47-counter] <= (memory_mode==sram_mode) ? sram_so :
                                        (memory_mode==nor_fash_mode) ? flash_so : 1'b0;
                end
            end
            if(instr_mode==half_mode) begin
                if(counter > 7'd31 && counter < 7'd56 && !we) begin
                    data[55-counter] <= (memory_mode==sram_mode) ? sram_so :
                                        (memory_mode==nor_fash_mode) ? flash_so : 1'b0;
                end
            end
        end
    end
end

assign op_r = (memory_mode==sram_mode) ? 
                    ((counter == 7'd63 && sck == 1) ? 1'b1 : 1'b0) : 
              (memory_mode==nor_fash_mode) ? 
                    ((counter == 7'd63 && sck == 1) ? 1'b1 : 1'b0) :
              (memory_mode==perpheral_mode) ? 
                    (1'b0) :
              1'b0;


endmodule


module main;
        reg [23:0] addr=24'hf0f0f0;             
        reg we=1;                       
        reg clk=0;                      
        reg [31:0] data_in=32'habababab;           
        wire [31:0] data_out;    
        wire op_r;               
        reg enable=1;                   
        reg [1:0] instr_mode=2'b00;         
        //extra fpga inputs

        wire sram_ce;             
        wire flash_ce;            
        wire sck;                 
        wire sram_so;                  
        wire flash_so;                 
        wire sram_si;            
        wire flash_si;           
        reg reset=0;

    memory_controller_module uut(

        .addr(addr),             
        .we(we),                       
        .clk(clk),                      
        .data_in(data_in),           
        .data_out(data_out),    
        .op_r(op_r),               
        .enable(enable),                   
        .instr_mode(instr_mode),         

        .sram_ce(sram_ce),             
        .flash_ce(flash_ce),            
        .sck(sck),                 
        .sram_so(sram_so),                  
        .flash_so(flash_so),                 
        .sram_si(sram_si),            
        .flash_si(flash_si),           
        .reset(reset)
        );

    always begin
        #10
        clk = ~clk;
    end

    initial begin
        reset=1;
        #1
        reset=0;
    end

    initial begin
        $dumpfile("final_memory_controller.vcd");
        $dumpvars(0,main);

        #5000
        $finish();
    end


endmodule



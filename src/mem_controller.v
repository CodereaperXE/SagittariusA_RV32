// 4/7/2025 spi memory controller RB

module memory_controller(
    input [23:0] addr,              // address 
    input we,                       // write enable
    input clk,                      // clk
    input [31:0] data_in,           // data in
    output wire [31:0] data_out,    // data out
    output reg ce,                  // chip enable
    output reg sck,                 // spi clock
    input so,                       // serial output (from psram)
    output wire si,                 // serial input  (from psram)
    input reset,                    // reset
    output op_r,                    // output data ready
    output [6:0] c,                 // internal counter (temporary)
    output ledg,                    // output green led (temporary)
    output ledr                     // output reg led   (temporary)
);

localparam IDLE = 1'b0, BUSY = 1'b1;
reg state = IDLE;
reg [6:0] counter = 7'd0;
reg [7:0] cmd = 8'd0;
reg [31:0] data = 32'd0;
localparam read_cmd= 8'h03, write_cmd = 8'h02;

//temporary
assign c = counter;
assign ledr = ~si; //output red led (temporary)
assign ledg= ~so;
//--------

//serial output logic
assign si = (counter < 8) ? cmd[7-counter] :
            (counter < 32) ? addr[31-counter] :
            (counter < 64 && we) ? data_in[63-counter] : 
            1'b0;

assign data_out = data;
assign op_r = (counter == 7'd63 && sck == 1) ? 1'b1 : 1'b0;


always@(posedge clk or posedge reset) begin
    if(reset) begin
        sck <= 1;
        ce <= 0;
        counter <= 0;
        state <= IDLE;
    end 
    else begin

        //sclk logic

        if(state == BUSY)
            if(ce)
                sck <= ~sck;
            else if(ce==0)
                sck <= 0;

        //read or write control

        if(state == IDLE) begin
            cmd <= (we) ? write_cmd : read_cmd; //write or read cmd loading
            ce <= 1;
            state <= BUSY;
            sck <= 0;
        end

        //counter control

        if(ce && sck==1) begin
            if(counter>=7'd63) begin
                ce <= 0;
                counter <= 0;
                state <= IDLE;

            end
            else
                counter <= counter + 1;
        end

        //input control

        if(sck==0)
            if(counter > 7'd31 && counter < 7'd64 && !we) begin
                data[63-counter] <= so;
            end
        end

end


endmodule

module clk_div_converter(
    input wire clk_in,       // 33 MHz input clock
    output reg clk_out       // 1 Hz pulse (1-cycle high)
);
    reg [25:0] counter = 0;   // 26 bits can count up to 67,108,863

    always @(posedge clk_in) begin
        if (counter == 25'd329999) begin  // 0 to 32,999,999 = 33 million clocks
            counter <= 0;
            clk_out <= ~clk_out;
        end else begin
            counter <= counter + 1;
            // clk_out <= 0;
        end
    end


endmodule

module main(
    input CLK,        
    output ICE_SO,       
    input ICE_SI,      
    output SRAM_SS,     
    output LED_R,   
    input ICE_10,  
    output LED_G,
    output ICE_SCK
);

wire clk;
reg [23:0] addr = 24'h008000;
wire button;
wire green;
assign button = ~ICE_10;
assign green = ~LED_G;

reg [31:0] data_in = 32'hf0f0f0f0;
wire [31:0] data_out;
reg we = 1;
wire [6:0] counter;

clk_div_converter cdc(
    .clk_in(CLK),
    .clk_out(clk)
);

memory_controller mem(
    .clk(clk),
    .sck(ICE_SCK),
    .addr(addr),
    .reset(button),
    .so(ICE_SI),     
    .si(ICE_SO),
    .data_in(data_in),
    .data_out(data_out),
    .we(we),
    .c(counter),
    .ce(SRAM_SS),
    .ledg(LED_G),
    .ledr(LED_R)
);

// Toggle write enable when mem.counter == 64
// assign LED_R = ~clk;
always @(posedge clk) begin
    if (counter == 7'd0) begin
        we <= ~we;

    end
end



endmodule

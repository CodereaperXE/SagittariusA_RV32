module uart_tx #(
    parameter CLK_FREQ = 12000000,
    parameter BAUD     = 115200
)(
    output reg uart_tx,
    input      clk,
    input      reset,
    input [7:0] data,
    input      start,
    output reg busy
);
    localparam integer DIVI = (CLK_FREQ + (BAUD/2)) / BAUD;

    reg [15:0] counter = 0;
    reg baud_tick = 0;
    reg [3:0] bit_index = 0;
    reg [9:0] shifter = 10'b1111111111; // idle = high
    reg start_reg = 0;
    reg flag=0;

    // Baud tick generator
    always @(posedge clk) begin
        if (counter >= DIVI - 1) begin
            counter   <= 0;
            baud_tick <= 1;
        end else begin
            counter   <= counter + 1;
            baud_tick <= 0;
        end
    end

    // TX logic
    always @(posedge clk or posedge reset) begin
        if (start && !flag) begin
        	flag<=1;
        	start_reg<=1;
        end
        if (busy) start_reg <= 0;
        if (!start) flag <= 0;

        if (reset) begin
            uart_tx   <= 1'b1;
            busy      <= 1'b0;
            bit_index <= 0;
        end else if (start_reg && !busy) begin
            shifter   <= {1'b1, data, 1'b0}; // stop, data, start
            bit_index <= 0;
            busy      <= 1'b1;
        end else if (busy && baud_tick) begin
            uart_tx   <= shifter[bit_index];
            bit_index <= bit_index + 1;
            if (bit_index == 9) busy <= 1'b0; // finished sending
        end
    end
endmodule


// module main(
//     input  CLK,       // 12 MHz clock
//     output UART_TX,   // UART TX pin
//     input  ICE_SW2    // pushbutton for start
// );
//     reg [7:0] data = "B"; // ASCII 'B'

//     wire busy;
//     reg start = 0;

//     wire button = ~ICE_SW2; 

//     // Instantiate UART
//     uart_tx uart_inst (
//         .uart_tx(UART_TX),
//         .clk(CLK),
//         .reset(1'b0), // no global reset for now
//         .data(data),
//         .start(start),
//         .busy(busy)
//     );

//     // Button edge detection for start pulse
//     // always @(posedge CLK) begin
//     //     if (button && !busy && !flag) begin
//     //         start <= 1;
//     //         flag  <= 1;
//     //     end else begin
//     //         start <= 0; // keep start only 1 cycle
//     //         if (!button) flag <= 0; // reset flag when button released
//     //     end
//     // end

//     always@(CLK) begin
//     	if(button) start<=1;
//     	if(!button) start<=0;
//     end

// endmodule

module clk_div_module(
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

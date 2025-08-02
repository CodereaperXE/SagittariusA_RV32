
// 10/7/25
`timescale 1 ns / 10 ps
`include "cpu.v"

    
module main;
    reg pc_enable=0;
    reg clk=0;
    reg memsel_mux_select=0;
    reg mem_write_enable=0;
    wire mem_op_r;
    reg ir_reg_enable=0;
    wire [31:0] ir_reg_out;
    reg rf_we=0;
    reg [1:0] regfile_mux_select=2'd0;
    reg [3:0] imm_src=4'd0;
    reg [1:0] opsel1_select=2'b00;
    reg [1:0] opsel2_select=2'd0;
    wire zero;
    reg alu_reg_enable=0;
    reg alu_reg_mux_select=0;
    reg reset=0;
    reg mem_enable=0;
    wire [3:0] alu_sel;
    reg old_pc_enable=0;
    reg mem_reg_enable=0;
    reg [1:0] instr_mode=0; 
    wire negative;

    wire nclk;
    assign nclk = ~clk;


    wire [6:0] opcode;
    wire [14:12] func3;
    wire [31:24] func7;

    assign opcode = ir_reg_out[6:0];
    assign func3 = ir_reg_out[14:12];
    assign func7 = ir_reg_out[31:25]; 

    parameter duration=1000;

    cpu_module uut(
        .pc_enable(pc_enable),
        .clk(clk),
        .memsel_mux_select(memsel_mux_select),
        .mem_write_enable(mem_write_enable),
        .mem_op_r(mem_op_r),
        .ir_reg_enable(ir_reg_enable),
        .ir_reg_out(ir_reg_out),
        .rf_we(rf_we),
        .regfile_mux_select(regfile_mux_select),
        .imm_src(imm_src),
        .opsel1_select(opsel1_select),
        .opsel2_select(opsel2_select),
        .zero(zero),
        .alu_reg_enable(alu_reg_enable),
        .alu_reg_mux_select(alu_reg_mux_select),
        .reset(reset),
        .mem_enable(mem_enable),
        .alu_sel(alu_sel),
        .old_pc_enable(old_pc_enable),
        .mem_reg_enable(mem_reg_enable),
        .instr_mode(instr_mode),
        .negative(negative)
        );


    reg [7:0] counter=4'd0;

    always begin
        #10
        clk = ~clk;
    end

    initial begin
        reset=1;
        #1
        reset=0;
        // counter=0;
        // #1
        // pc_enable=0;
        // memsel_mux_select=0;
        // mem_enable=1;
        // #8
        // mem_enable=0;
        // state=0;
        // nstate=0;
        // #70
        // ir_reg_enable=1;
        // #20
        // ir_reg_enable=0;
    end


    //alu src selection (alu control)
    assign alu_sel = (func3==3'b010 && opcode==7'b0000011) ? 4'b0000 : //load lw
                     // (func3==3'b001 && opcode==7'b0000011) ? 4'b0000 : //lb
                     (func3==3'b010 && opcode==7'b0100011) ? 4'b0000 : //store sw
                     (func3==3'b000 && opcode==7'b1100011) ? 4'b0000 : //branch bne beq
                     (opcode==7'b1101111) ? 4'b0000 : //jal
                     (opcode==7'b1100111) ? 4'b0000 : //jalr (immediate type)
                     (opcode==7'b0110111) ? 4'b0010 : //U type lui instruction
                     (opcode==7'b0010111) ? 4'b0000 : //U type auipc instruction

                     (opcode==7'b0010011 && func3==3'b000) ? 4'b0000 : //addi
                     (opcode==7'b0010011 && func3==3'b001 && func7==7'b0000000) ? 4'b0011 : //slli
                     (opcode==7'b0010011 && func3==3'b010) ? 4'b1001 : //slti
                     (opcode==7'b0010011 && func3==3'b011) ? 4'b1010 : //sltiu
                     (opcode==7'b0010011 && func3==3'b100) ? 4'b0110 : //xori
                     (opcode==7'b0010011 && func3==3'b101 && func7==7'b0000000) ? 4'b0100 : //srli
                     (opcode==7'b0010011 && func3==3'b101 && func7==7'b0100000) ? 4'b0101 : //srai
                     (opcode==7'b0010011 && func3==3'b110) ? 4'b0111 : //ori
                     (opcode==7'b0010011 && func3==3'b111) ? 4'b1000 : //andi
                     4'b0000;

    reg [7:0] state=8'd0;
    reg [7:0] nstate=8'd0;


    
    always@(*) begin
        case(state)
            8'd0: nstate=8'd1;
            8'd1: nstate=8'd2;
            8'd2: begin
                if(mem_op_r==1) //wait for memory complete
                    nstate=8'd3;
                    ir_reg_enable=1;
                end
            8'd3: begin
                    case(opcode)
                        7'b0000011: begin
                            nstate=8'd4; //load type
                            imm_src=4'b0000;
                        end
                        7'b0100011: begin
                            nstate=8'd8; //store type
                            imm_src=4'b0001;
                        end
                        7'b1100011: begin
                            nstate=8'd10; //branch type
                            imm_src=4'b0010;
                        end
                        7'b1101111: begin
                            nstate=8'd12; //jump type jal
                            imm_src=4'b0011; 
                        end
                        7'b1100111: begin
                            nstate=8'd14; //jalr (immediate setting)
                            imm_src=4'b0000;
                        end
                        7'b0110111: begin
                            nstate=8'd16; //U type lui instruction
                            imm_src=4'b0100;
                        end
                        7'b0010111: begin
                            nstate=8'd17; //U type auipc instruction
                            imm_src=4'b0100;
                        end
                        7'b0110011: begin //R type instruction
                            nstate=8'd18;
                        end
                        7'b0010011: begin //I type immediate 
                            nstate=8'd19;
                            if(func3==3'b000) imm_src=4'b0000; //addi
                            else if(func3==3'b001 && func7==7'b0000000) imm_src=4'b0101;  //slli
                            else if(func3==3'b010) imm_src=4'b0000; //slti
                            else if(func3==3'b011) imm_src=4'b0100; //sltiu
                            else if(func3==3'b100) imm_src=4'b0000; //xori
                            else if(func3==3'b101 && func7==7'b0000000) imm_src=4'b0100; //srli
                            else if(func3==3'b101 && func7==7'b0100000) imm_src=4'b0100; //srai
                            else if(func3==3'b110) imm_src=4'b0000; //ori
                            else if(func3==3'b111) imm_src=4'b0000; //andi
                            else imm_src=4'b0000;
                        end


                    endcase

                end
            //load type instruction
            8'd4: nstate=8'd5;
            8'd5: nstate=8'd6;
            8'd6: begin
                    if(mem_op_r==1) //wait for memory complete
                        nstate=8'd7;
                        mem_reg_enable=1;
                end
            8'd7: begin
                    case(func3)
                        3'b000: begin 
                                    imm_src=4'b0110; //lb
                                    instr_mode=2'b01;
                                end
                        3'b001: begin 
                                    imm_src=4'b0111; //lh
                                    instr_mode=2'b10;
                                end
                        3'b010: begin
                                    imm_src=4'b1100; //lw
                                    instr_mode=2'b00;
                                end
                        3'b100: begin 
                                    imm_src=4'b1000; //lbu
                                    instr_mode=2'b01;
                                end
                        3'b101: begin 
                                    imm_src=4'b1001; //lhu
                                    instr_mode=2'b10;
                                end
                        default: begin 
                                    imm_src=4'b1100;
                                    instr_mode=2'b00;
                                end
                    endcase
                        
                    nstate=8'd0;

                end

            //store type instruction
            // 8'd7: nstate=8'd8;
            // 8'd8:  begin
            //         if(mem_op_r==1) //wait for memory complete
            //             nstate=8'd0;
            //     end
            // 8'd8: nstate=8'd9;
            8'd8:
                begin
                    case(func3)
                        3'b000: begin //sb
                                    instr_mode=2'b01;
                                end
                        3'b001: begin //sh
                                    instr_mode=2'b10;
                                end
                        3'b010: begin //sw
                                    instr_mode=2'b00;
                                end
                        default: instr_mode=2'b00;
                    endcase
                    nstate=8'd9;
                end
            8'd9:
                begin
                    if(mem_op_r==1) nstate=8'd0;
                end
            //end of store type
            //branch type instruction
            8'd10: nstate=8'd11;
            8'd11: nstate=8'd0;
            //end of branch type instruction

            //jump type instruction
            8'd12: nstate=8'd13;
            8'd13: nstate=8'd0;
            //jalr immediate type instruction
            8'd14: nstate=8'd15;
            8'd15: nstate=8'd0;
            //end of jump type instrutions
            //U type lui instruction
            8'd16: nstate=8'd0;
            //U type auipc instruction
            8'd17: nstate=8'd0;
            //R type instructions
            8'd18: nstate=8'd0;
            //I type instructions
            8'd19: nstate=8'd0;

            //branch type instruction
            // 8'd9: nstate=8'd10;
            // 8'd10: nstate=8'd0;
            // //jump type instruction
            // 8'd11: nstate=8'd12;
            // 8'd12: nstate=8'd0;
            // //jalr immediate type instruction
            // 8'd13: nstate=8'd14;
            // 8'd14: nstate=8'd0;
            // //U type lui instruction
            // 8'd15: nstate=8'd0;
            // //U type auipc instruction
            // 8'd16: nstate=8'd0;
            // //R type instruction
            // 8'd17: nstate=8'd0;
            // //I type instruction other than lw
            // 8'd18: nstate=8'd0;

            default:nstate=8'd0;
        endcase
    end


    always@(posedge nclk) begin
        state <= nstate;

        case(state) 
            8'd0:
                begin
                    rf_we=0;
                    instr_mode=2'b00;
                end

            8'd1: //load from pc to memory
                begin
                    // pc_enable=0;
                    memsel_mux_select=0;
                    mem_enable=1;
                    // increment pc + 4
                    opsel1_select=2'b01;
                    opsel2_select=2'b01;
                    alu_reg_mux_select=1;
                    pc_enable=1;

                    old_pc_enable=1; //for branch and jump instruction 14/7/25
                    rf_we=0;
                end
            8'd2: //load from memory to ir
                begin
                    mem_enable=0;
                    imm_src=3'd0;

                    //disable increment pc + 4
                    opsel1_select=2'b00;
                    opsel2_select=2'b00;
                    alu_reg_mux_select=0;
                    pc_enable=0;

                    old_pc_enable=0;
                    
                end
            8'd3: //load from rf_file to rf_reg
                begin
                    ir_reg_enable=0;
                end

            // load type instruction

            8'd4: //load instruction
                 begin
                    opsel1_select=2'b00;
                    opsel2_select=2'b00;

                    alu_reg_mux_select=0;
                    //alu set to add I
                    alu_reg_enable=1;
                    memsel_mux_select=1;
                 end
            8'd5: 
                begin
                    alu_reg_enable=0;
                    mem_enable=1;
                end
            8'd6: //mem wait
                begin
                    mem_enable=0;
                    regfile_mux_select=2'b10;
                end
            8'd7:
                begin
                    mem_reg_enable=0;
                    rf_we=1;
                end

            //store instruction
            8'd8:
                begin
                    opsel1_select=2'b00;
                    opsel2_select=2'b00;

                    alu_reg_mux_select=1;
                    
                    alu_reg_enable=0;
                    
                    memsel_mux_select=1;

                    mem_enable=1;
                    mem_write_enable=1;
                end
            8'd9:
                begin
                    mem_write_enable=0;
                    mem_enable=0;
                end
            //branch type

            8'd10:
                begin
                    opsel1_select=2'b00;
                    opsel2_select=2'b10;
                    pc_enable=0;
                end
            8'd11:
                begin
                    alu_reg_mux_select=1;
                    if(func3==3'b000 && zero) begin //beq
                        opsel1_select=2'b10;
                        opsel2_select=2'b00;
                        pc_enable=1;
                    end
                    else if(func3==3'b010 && !zero) begin //bne
                        opsel1_select=2'b10;
                        opsel2_select=2'b00;
                        pc_enable=1;
                    end
                    else begin
                        pc_enable=0;
                    end
                end
            //end of branch type

            //jump instruction
            8'd12:
                begin
                    regfile_mux_select=1;
                    opsel1_select=2'b10;
                    opsel2_select=2'b01;
                    alu_reg_mux_select=1; //better to remove the register itself not serving any purpose
                    rf_we=1;
                end
            8'd13:
                begin
                    opsel1_select=2'b10;
                    opsel2_select=2'b00;
                    alu_reg_mux_select=1;
                    rf_we=0;
                    pc_enable=1;
                end
            //end of jump type instruction

            //jalr instruction
            8'd14:
                begin
                    opsel1_select=2'b10;
                    opsel2_select=2'b01;
                    rf_we=1;
                    regfile_mux_select=1;
                    alu_reg_mux_select=1;
                end
            8'd15:
                begin
                    rf_we=0;

                    opsel1_select=2'b00;
                    opsel2_select=2'b00;
                    pc_enable=1;
                end

            // end of jump instruction
            //U type lui instruction
            8'd16:
                begin
                    regfile_mux_select=1;
                    alu_reg_mux_select=1;
                    opsel2_select=2'b00;
                    rf_we=1;
                end
            // end of U type lui instruction
            //U type auipc instruction
            8'd17:
                begin
                    regfile_mux_select=1;   
                    alu_reg_mux_select=1;
                    opsel1_select=2'b10;
                    opsel2_select=2'b00;
                    pc_enable=1;
                end
            //end of U type auipc instruction
            //R type instruction
            8'd18:
                begin
                    alu_reg_mux_select=1;
                    opsel1_select=2'b00;
                    opsel2_select=2'b10;
                    regfile_mux_select=1;
                    rf_we=1;
                end
            //end of R type instruction
            //I type instruction other than load type
            8'd19:
                begin
                    alu_reg_mux_select=1;
                    opsel1_select=2'b00;
                    opsel2_select=2'b00;
                    regfile_mux_select=1;
                    rf_we=1;
                end
            // end of I type instructions
            

            //new instructions
            // 8'd4: 
            //     begin
            //         opsel1_select=2'b00;
            //         opsel2_select=2'b00;

            //         alu_reg_mux_select=1;
            //         memsel_mux_select=1;
            //         mem_enable=1;
            //         regfile_mux_select=2'b00;
            //         rf_we=1;
            //     end
            // 8'd5: 
            //         mem_enable=0;
            // 8'd6: 
            //     begin
            //         alu_reg_mux_select=0;
            //         memsel_mux_select=0;
            //         rf_we=0;
            //     end
            // //end of load type instruction

            // //store type instruction
            // 8'd7:
            //     begin
            //         opsel1_select=2'b00;
            //         opsel2_select=2'b00;

            //         alu_reg_mux_select=1;
            //         memsel_mux_select=1;
            //         mem_write_enable=1;
            //         mem_enable=1;
            //     end
            // 8'd8:
            //     begin
            //         mem_enable=0;
            //     end
            // //end of store type instruction

            // //branch type instruction
            // 8'd9:
            //     begin
            //         opsel1_select=2'b00;
            //         opsel2_select=2'b10;
            //         pc_enable=0;
            //     end
            // 8'd10:
            //     begin
            //         alu_reg_mux_select=1;
            //         if(func3==3'b000 && zero) begin //beq
            //             opsel1_select=2'b10;
            //             opsel2_select=2'b00;
            //             pc_enable=1;
            //         end
            //         else if(func3==3'b010 && !zero) begin //bne
            //             opsel1_select=2'b10;
            //             opsel2_select=2'b00;
            //             pc_enable=1;
            //         end
            //         else begin
            //             pc_enable=0;
            //         end
            //     end
            // //end of branch type instruction
            
            // //jump type instruction
            // 8'd11:
            //     begin
            //         regfile_mux_select=1;
            //         opsel1_select=2'b10;
            //         opsel2_select=2'b01;
            //         alu_reg_mux_select=1; //better to remove the register itself not serving any purpose
            //         rf_we=1;
            //     end
            // 8'd12:
            //     begin
            //         opsel1_select=2'b10;
            //         opsel2_select=2'b00;
            //         alu_reg_mux_select=1;
            //         rf_we=0;
            //         pc_enable=1;
            //     end
            // //end of jump type instruction

            // //jalr instruction
            // 8'd13:
            //     begin
            //         opsel1_select=2'b10;
            //         opsel2_select=2'b01;
            //         rf_we=1;
            //         regfile_mux_select=1;
            //         alu_reg_mux_select=1;
            //     end
            // 8'd14:
            //     begin
            //         rf_we=0;

            //         opsel1_select=2'b00;
            //         opsel2_select=2'b00;
            //         pc_enable=1;
            //     end
            // //end of jalr instruction

            // //U type lui instruction
            // 8'd15:
            //     begin
            //         alu_reg_mux_select=1;
            //         opsel2_select=2'b00;
            //         rf_we=1;
            //     end
            // //end of U type lui instruction
            // //U type auipc instruction
            // 8'd16:
            //     begin
            //         alu_reg_mux_select=1;
            //         opsel1_select=2'b10;
            //         opsel2_select=2'b00;
            //         pc_enable=1;
            //     end
            // //end of U type auipc instruction

            // //R type instruction
            // 8'd17:
            //     begin
            //         alu_reg_mux_select=1;
            //         opsel1_select=2'b00;
            //         opsel2_select=2'b10;
            //         regfile_mux_select=1;
            //         rf_we=1;
            //     end
            // //end of R type instruction
            

            // //I type instruction other than load type
            // 8'd18:
            //     begin
            //         alu_reg_mux_select=1;
            //         opsel1_select=2'b00;
            //         opsel2_select=2'b00;
            //         regfile_mux_select=1;
            //         rf_we=1;
            //     end
            //end of I type instructions
            default:
                ;
        endcase
    end


    // always@(posedge nclk) begin
    //     counter <= counter+1;
    //     if(counter == 7'd3) begin // load from memory to ir
    //         ir_reg_enable=1;
    //     end
    //     if(counter == 7'd4) begin // select immsrc 
    //         ir_reg_enable=0;
    //         imm_src= 2'b00;

    //     end
    //     if(counter == 7'd5) begin //load from rf to rf_reg
    //         ir_reg_enable=0;
    //     end

    //     if(counter==7'd6) begin // load only alu reg
    //         alu_reg_enable = 1;
    //     end
    //     if(counter==7'd7) begin
    //         alu_reg_enable=0;
    //     end
    // end



    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0,main);

        #(duration)

        $finish();

    end
endmodule
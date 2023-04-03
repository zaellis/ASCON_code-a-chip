`timescale 1ns / 10ps

module tb_wb_ASCON();

    localparam  CLK_PERIOD = 10; //100MHz

    logic clk, nRST;
    
    logic [31:0] tb_wb_adr_i;
    logic [31:0] tb_wb_dat_i;
    logic [3:0]  tb_wb_sel_i;
    logic tb_wb_we_i;
    logic tb_wb_cyc_i;
    logic tb_wb_stb_i;

    logic tb_wb_ack_o;
    logic [31:0] tb_wb_dat_o;

    integer tb_test_num;
    string tb_test_case;

    wb_ASCON DUT(
        .clk(clk),
        .nRST(nRST),
        .wb_adr_i(tb_wb_adr_i),
        .wb_dat_i(tb_wb_dat_i),
        .wb_sel_i(tb_wb_sel_i),
        .wb_we_i(tb_wb_we_i),
        .wb_cyc_i(tb_wb_cyc_i),
        .wb_stb_i(tb_wb_stb_i),
        .wb_ack_o(tb_wb_ack_o),      
        .wb_dat_o(tb_wb_dat_o)
    );

    task wb_transaction;
        input [31:0] wb_addr;
        input [31:0] wb_dat;
        input [3:0] wb_sel;
        input wb_we;
        input string signal_name;
    begin
        @(posedge clk);
        tb_wb_adr_i = wb_addr;
        tb_wb_sel_i = wb_sel;
        tb_wb_we_i = wb_we;
        tb_wb_cyc_i = 1'b1;
        tb_wb_stb_i = 1'b1;
        if(wb_we) tb_wb_dat_i = wb_dat;
        else begin
            tb_wb_dat_i = 0;
            #(CLK_PERIOD / 10);
            while(~tb_wb_ack_o) begin
                @(posedge clk);
                #(CLK_PERIOD / 10);
            end
            if(wb_dat == tb_wb_dat_o) begin // Check passed
                $info("Correct %s output during %s test case", signal_name, tb_test_case);
            end
            else begin // Check failed
                $error("Incorrect %s output during %s test case. Expecting %h Actual %h", signal_name, tb_test_case, wb_dat, tb_wb_dat_o);
            end
        end
        @(posedge clk);
        tb_wb_cyc_i = 1'b0;
        tb_wb_stb_i = 1'b0;
    end
    endtask

    task reset_dut;
    begin
        // Activate the reset
        nRST = 1'b0;

        // Maintain the reset for more than one cycle
        @(posedge clk);
        @(posedge clk);

        // Wait until safely away from rising edge of the clock before releasing
        @(negedge clk);
        nRST = 1'b1;

        // Leave out of reset for a couple cycles before allowing other stimulus
        // Wait for negative clock edges, 
        // since inputs to DUT should normally be applied away from rising clock edges
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    always
    begin
        // Start with clock low to avoid false rising edge events at t=0
        clk = 1'b0;
        // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
        #(CLK_PERIOD/2.0);
        clk = 1'b1;
        // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
        #(CLK_PERIOD/2.0);
    end

    initial begin
        tb_wb_adr_i = '0;
        tb_wb_dat_i = '0;
        tb_wb_sel_i = '0;
        tb_wb_we_i = '0;
        tb_wb_cyc_i = '0;
        tb_wb_stb_i = '0;

        tb_test_num = 1;
        tb_test_case = "Basic Encrypt";

        reset_dut();

        wb_transaction(32'h00000008, 32'h0C0D0E0F, 4'b1111, 1'b1, "Key_reg_0");
        wb_transaction(32'h0000000C, 32'h08090A0B, 4'b1111, 1'b1, "Key_reg_1");
        wb_transaction(32'h00000010, 32'h04050607, 4'b1111, 1'b1, "Key_reg_2");
        wb_transaction(32'h00000014, 32'h00010203, 4'b1111, 1'b1, "Key_reg_3");

        wb_transaction(32'h00000018, 32'h0C0D0E0F, 4'b1111, 1'b1, "Nonce_reg_0");
        wb_transaction(32'h0000001C, 32'h08090A0B, 4'b1111, 1'b1, "Nonce_reg_1");
        wb_transaction(32'h00000020, 32'h04050607, 4'b1111, 1'b1, "Nonce_reg_2");
        wb_transaction(32'h00000024, 32'h00010203, 4'b1111, 1'b1, "Nonce_reg_3");

        wb_transaction(32'h00000028, 32'h04050607, 4'b1111, 1'b1, "AD_reg_0");
        wb_transaction(32'h0000002C, 32'h00010203, 4'b1111, 1'b1, "AD_reg_1");
        wb_transaction(32'h00000030, 32'h0C0D0E0F, 4'b1111, 1'b1, "AD_reg_2");
        wb_transaction(32'h00000034, 32'h08090A0B, 4'b1111, 1'b1, "AD_reg_3");

        wb_transaction(32'h00000048, 32'h04050607, 4'b1111, 1'b1, "RAM_addr_0");
        wb_transaction(32'h0000004C, 32'h00010203, 4'b1111, 1'b1, "RAM_addr_1");
        wb_transaction(32'h00000050, 32'h0C0D0E0F, 4'b1111, 1'b1, "RAM_addr_2");
        wb_transaction(32'h00000054, 32'h08090A0B, 4'b1111, 1'b1, "RAM_addr_3");
        wb_transaction(32'h00000058, 32'h14000000, 4'b1111, 1'b1, "RAM_addr_4");
        wb_transaction(32'h0000005C, 32'h10111213, 4'b1111, 1'b1, "RAM_addr_5");
        wb_transaction(32'h00000060, 32'h1C000000, 4'b1111, 1'b1, "RAM_addr_6");
        wb_transaction(32'h00000064, 32'h18191A1B, 4'b1111, 1'b1, "RAM_addr_7");
        wb_transaction(32'h00000068, 32'h04050607, 4'b1111, 1'b1, "RAM_addr_8");
        wb_transaction(32'h0000006C, 32'h00010203, 4'b1111, 1'b1, "RAM_addr_9");
        wb_transaction(32'h00000070, 32'h0C0D0E0F, 4'b1111, 1'b1, "RAM_addr_10");
        wb_transaction(32'h00000074, 32'h08090A0B, 4'b1111, 1'b1, "RAM_addr_11");
        wb_transaction(32'h00000078, 32'h14000000, 4'b1111, 1'b1, "RAM_addr_12");
        wb_transaction(32'h0000007C, 32'h10111213, 4'b1111, 1'b1, "RAM_addr_13");
        wb_transaction(32'h00000080, 32'h1C000000, 4'b1111, 1'b1, "RAM_addr_14");
        wb_transaction(32'h00000084, 32'h18191A1B, 4'b1111, 1'b1, "RAM_addr_15");
        wb_transaction(32'h00000088, 32'h04050607, 4'b1111, 1'b1, "RAM_addr_16");
        wb_transaction(32'h0000008C, 32'h00010203, 4'b1111, 1'b1, "RAM_addr_17");
        wb_transaction(32'h00000090, 32'h0C0D0E0F, 4'b1111, 1'b1, "RAM_addr_18");
        wb_transaction(32'h00000094, 32'h08090A0B, 4'b1111, 1'b1, "RAM_addr_19");
        wb_transaction(32'h00000098, 32'h14000000, 4'b1111, 1'b1, "RAM_addr_20");
        wb_transaction(32'h0000009C, 32'h10111213, 4'b1111, 1'b1, "RAM_addr_21");
        wb_transaction(32'h000000A0, 32'h1C000000, 4'b1111, 1'b1, "RAM_addr_22");
        wb_transaction(32'h000000A4, 32'h18191A1B, 4'b1111, 1'b1, "RAM_addr_23");
        wb_transaction(32'h000000A8, 32'h04050607, 4'b1111, 1'b1, "RAM_addr_24");
        wb_transaction(32'h000000AC, 32'h00010203, 4'b1111, 1'b1, "RAM_addr_25");
        wb_transaction(32'h000000B0, 32'h0C0D0E0F, 4'b1111, 1'b1, "RAM_addr_26");
        wb_transaction(32'h000000B4, 32'h08090A0B, 4'b1111, 1'b1, "RAM_addr_27");
        wb_transaction(32'h000000B8, 32'h14000000, 4'b1111, 1'b1, "RAM_addr_28");
        wb_transaction(32'h000000BC, 32'h10111213, 4'b1111, 1'b1, "RAM_addr_29");
        wb_transaction(32'h000000C0, 32'h1C000000, 4'b1111, 1'b1, "RAM_addr_30");
        wb_transaction(32'h000000C4, 32'h18191A1B, 4'b1111, 1'b1, "RAM_addr_31");

        wb_transaction(32'h00000004, {16'd0, 16'b1111100000101000}, 4'b1111, 1'b1, "CNTRL_reg");

    end
endmodule
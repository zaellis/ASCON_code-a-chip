`timescale 1ns / 10ps

module tb_wb_slave();

    localparam  CLK_PERIOD = 10; //100MHz

    logic tb_wb_clk_i;
    logic tb_wb_rst_i;

    logic [31:0] tb_wb_adr_i;
    logic [31:0] tb_wb_dat_i;
    logic [3:0]  tb_wb_sel_i;
    logic tb_wb_we_i;
    logic tb_wb_cyc_i;
    logic tb_wb_stb_i;

    logic tb_wb_ack_o;
    logic [31:0] tb_wb_dat_o;

    logic [3:0] tb_state;
    logic [127:0] tb_Tag;
    logic [63:0] tb_CTblock;
    logic tb_CTv;
    logic tb_Tv;
    logic [2:0] tb_block_request;

    logic tb_start;
    logic [1:0] tb_mode;
    logic [127:0] tb_key;
    logic [127:0] tb_nonce;
    logic [63:0] tb_blockout;
    logic [6:0] tb_datalen;
    logic [3:0] tb_AD_len;

    integer tb_test_num;
    string tb_test_case;

    wb_slave DUT (
        .wb_clk_i(tb_wb_clk_i),
        .wb_rst_i(tb_wb_rst_i),
        .wb_adr_i(tb_wb_adr_i),
        .wb_dat_i(tb_wb_dat_i),
        .wb_sel_i(tb_wb_sel_i),
        .wb_we_i(tb_wb_we_i),
        .wb_cyc_i(tb_wb_cyc_i),
        .wb_stb_i(tb_wb_stb_i),
        .wb_ack_o(tb_wb_ack_o),      
        .wb_dat_o(tb_wb_dat_o),
        .state(tb_state),
        .Tag(tb_Tag),
        .CTblock(tb_CTblock),
        .CTv(tb_CTv),
        .Tv(tb_Tv),
        .block_request(tb_block_request),
        .start(tb_start),
        .mode(tb_mode),
        .key(tb_key),
        .nonce(tb_nonce),
        .blockout(tb_blockout),
        .datalen(tb_datalen),
        .AD_len(tb_AD_len)
    );

    task reset_dut;
    begin
        // Activate the reset
        tb_wb_rst_i = 1'b1;

        // Maintain the reset for more than one cycle
        @(posedge tb_wb_clk_i);
        @(posedge tb_wb_clk_i);

        // Wait until safely away from rising edge of the clock before releasing
        @(negedge tb_wb_clk_i);
        tb_wb_rst_i = 1'b0;

        // Leave out of reset for a couple cycles before allowing other stimulus
        // Wait for negative clock edges, 
        // since inputs to DUT should normally be applied away from rising clock edges
        @(negedge tb_wb_clk_i);
        @(negedge tb_wb_clk_i);
    end
    endtask   
    
    task wb_transaction;
        input [31:0] wb_addr;
        input [31:0] wb_dat;
        input [3:0] wb_sel;
        input wb_we;
        input string signal_name;
    begin
        @(posedge tb_wb_clk_i);
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
                @(posedge tb_wb_clk_i);
                #(CLK_PERIOD / 10);
            end
            if(wb_dat == tb_wb_dat_o) begin // Check passed
                $info("Correct %s output during %s test case", signal_name, tb_test_case);
            end
            else begin // Check failed
                $error("Incorrect %s output during %s test case. Expecting %h Actual %h", signal_name, tb_test_case, wb_dat, tb_wb_dat_o);
            end
        end
        @(posedge tb_wb_clk_i);
        tb_wb_cyc_i = 1'b0;
        tb_wb_stb_i = 1'b0;
    end
    endtask

    task wb_pipeline;
        input [31:0] wb_addr;
        input [31:0] wb_dat;
        input [3:0] wb_sel;
        input string signal_name;
    begin
        @(posedge tb_wb_clk_i);
        tb_wb_adr_i = wb_addr;
        tb_wb_sel_i = wb_sel;
        tb_wb_we_i = 1'b1;
        tb_wb_cyc_i = 1'b1;
        tb_wb_stb_i = 1'b1;
        tb_wb_dat_i = wb_dat;
        @(posedge tb_wb_clk_i);
        tb_wb_we_i = 0;
        @(posedge tb_wb_clk_i);
        #(CLK_PERIOD / 10);
        if(wb_dat == tb_wb_dat_o) begin // Check passed
            $info("Correct %s output during %s test case", signal_name, tb_test_case);
        end
        else begin // Check failed
            $error("Incorrect %s output during %s test case. Expecting %h Actual %h", signal_name, tb_test_case, wb_dat, tb_wb_dat_o);
        end
        tb_wb_cyc_i = 1'b0;
        tb_wb_stb_i = 1'b0;
    end
    endtask


    task check_out;
        input logic [31:0] real_out;
        input logic [31:0] expected_out;
        input string signal_name;
    begin
        if(expected_out == real_out) begin // Check passed
            $info("Correct %s output during %s test case", signal_name, tb_test_case);
        end
        else begin // Check failed
            $error("Incorrect %s output during %s test case. Expecting %h Actual %h", signal_name, tb_test_case, expected_out, real_out);
        end
    end
    endtask

    always
    begin
        // Start with clock low to avoid false rising edge events at t=0
        tb_wb_clk_i = 1'b0;
        // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
        #(CLK_PERIOD/2.0);
        tb_wb_clk_i = 1'b1;
        // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
        #(CLK_PERIOD/2.0);
    end

    initial begin
        tb_wb_rst_i = '0;
        tb_wb_adr_i = '0;
        tb_wb_dat_i = '0;
        tb_wb_sel_i = '0;
        tb_wb_we_i = '0;
        tb_wb_cyc_i = '0;
        tb_wb_stb_i = '0;
        
        tb_state = '0;
        tb_Tag ='0;
        tb_CTblock ='0;
        tb_CTv ='0;
        tb_Tv = '0;
        tb_block_request = '0;

        tb_test_num = 0;

        // ************************************************************************
        // Test Case 1: Check Default Values
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Check Default Values";

        reset_dut();

        wb_transaction(32'h00000000, 32'd0, 4'b1111, 1'b0, "SR");
        wb_transaction(32'h00000004, 32'd0, 4'b1111, 1'b0, "CR");
        wb_transaction(32'h00000008, 32'd0, 4'b1111, 1'b0, "KR0");
        wb_transaction(32'h0000000C, 32'd0, 4'b1111, 1'b0, "KR1");
        wb_transaction(32'h00000010, 32'd0, 4'b1111, 1'b0, "KR2");
        wb_transaction(32'h00000014, 32'd0, 4'b1111, 1'b0, "KR3");
        wb_transaction(32'h00000018, 32'd0, 4'b1111, 1'b0, "NR0");
        wb_transaction(32'h0000001C, 32'd0, 4'b1111, 1'b0, "NR1");
        wb_transaction(32'h00000020, 32'd0, 4'b1111, 1'b0, "NR2");
        wb_transaction(32'h00000024, 32'd0, 4'b1111, 1'b0, "NR3");
        wb_transaction(32'h00000028, 32'd0, 4'b1111, 1'b0, "ADR0");
        wb_transaction(32'h0000002C, 32'd0, 4'b1111, 1'b0, "ADR1");
        wb_transaction(32'h00000030, 32'd0, 4'b1111, 1'b0, "ADR2");
        wb_transaction(32'h00000034, 32'd0, 4'b1111, 1'b0, "ADR3");
        wb_transaction(32'h00000038, 32'd0, 4'b1111, 1'b0, "PDR0");
        wb_transaction(32'h0000003C, 32'd0, 4'b1111, 1'b0, "PDR1");
        wb_transaction(32'h00000040, 32'd0, 4'b1111, 1'b0, "PDR2");
        wb_transaction(32'h00000044, 32'd0, 4'b1111, 1'b0, "PDR3");
        wb_transaction(32'h00000048, 32'd0, 4'b1111, 1'b0, "CDR0");
        wb_transaction(32'h0000004C, 32'd0, 4'b1111, 1'b0, "CDR1");
        wb_transaction(32'h00000050, 32'd0, 4'b1111, 1'b0, "CDR2");
        wb_transaction(32'h00000054, 32'd0, 4'b1111, 1'b0, "CDR3");
        wb_transaction(32'h00000058, 32'd0, 4'b1111, 1'b0, "TR0");
        wb_transaction(32'h0000005C, 32'd0, 4'b1111, 1'b0, "TR1");
        wb_transaction(32'h00000060, 32'd0, 4'b1111, 1'b0, "TR2");
        wb_transaction(32'h00000064, 32'd0, 4'b1111, 1'b0, "TR3");

        // ************************************************************************
        // Test Case 2: Status Register
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Status Register";

        wb_transaction(32'h00000000, 32'hBEEFCAFE, 4'b1111, 1'b1, "SR");
        wb_transaction(32'h00000000, 32'd0, 4'b1111, 1'b0, "SR");

        tb_state = 4'b1010;
        wb_transaction(32'h00000000, 32'h0000001a, 4'b1111, 1'b0, "SR");

        // ************************************************************************
        // Test Case 3: Control Register
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Control Register";

        wb_pipeline(32'h00000004, 32'b00000000000000000010101010101010, 4'b1111, "CR");

        //check_out(tb_start, 1'b1, "start"); //this is really hard to check but it was confirmed by eye
        check_out(tb_mode, 2'd1, "mode");
        check_out(tb_AD_len, 4'b0101, "AD_len");
        check_out(tb_datalen, 7'b0101010, "datalen");

        wb_transaction(32'h00000004, 32'b00000000000000000000101010101010, 4'b1111, 1'b0, "CR");

        check_out(tb_start, 1'b0, "start_autozero");

        // ************************************************************************
        // Test Case 4: Key Registers
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Key Registers";

        wb_transaction(32'h00000008, 32'hBEEFCAFE, 4'b1111, 1'b1, "KR0");
        wb_transaction(32'h00000008, 32'hBEEFCAFE, 4'b1111, 1'b0, "KR0");
        wb_transaction(32'h0000000C, 32'hBEEFCAFE, 4'b1111, 1'b1, "KR1");
        wb_transaction(32'h0000000C, 32'hBEEFCAFE, 4'b1111, 1'b0, "KR1");
        wb_transaction(32'h00000010, 32'hBEEFCAFE, 4'b1111, 1'b1, "KR2");
        wb_transaction(32'h00000010, 32'hBEEFCAFE, 4'b1111, 1'b0, "KR2");
        wb_transaction(32'h00000014, 32'hBEEFCAFE, 4'b1111, 1'b1, "KR3");
        wb_transaction(32'h00000014, 32'hBEEFCAFE, 4'b1111, 1'b0, "KR3");

        check_out(tb_key[31:0], 32'hBEEFCAFE, "Key Reg 0 Check");
        check_out(tb_key[63:32], 32'hBEEFCAFE, "Key Reg 1 Check");
        check_out(tb_key[95:64], 32'hBEEFCAFE, "Key Reg 2 Check");
        check_out(tb_key[127:96], 32'hBEEFCAFE, "Key Reg 3 Check");

        // ************************************************************************
        // Test Case 5: Nonce Registers
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Nonce Registers";

        wb_transaction(32'h00000018, 32'hBEEFCAFE, 4'b1111, 1'b1, "NR0");
        wb_transaction(32'h00000018, 32'hBEEFCAFE, 4'b1111, 1'b0, "NR0");
        wb_transaction(32'h0000001C, 32'hBEEFCAFE, 4'b1111, 1'b1, "NR1");
        wb_transaction(32'h0000001C, 32'hBEEFCAFE, 4'b1111, 1'b0, "NR1");
        wb_transaction(32'h00000020, 32'hBEEFCAFE, 4'b1111, 1'b1, "NR2");
        wb_transaction(32'h00000020, 32'hBEEFCAFE, 4'b1111, 1'b0, "NR2");
        wb_transaction(32'h00000024, 32'hBEEFCAFE, 4'b1111, 1'b1, "NR3");
        wb_transaction(32'h00000024, 32'hBEEFCAFE, 4'b1111, 1'b0, "NR3");

        check_out(tb_nonce[31:0], 32'hBEEFCAFE, "Nonce Reg 0 Check");
        check_out(tb_nonce[63:32], 32'hBEEFCAFE, "Nonce Reg 1 Check");
        check_out(tb_nonce[95:64], 32'hBEEFCAFE, "Nonce Reg 2 Check");
        check_out(tb_nonce[127:96], 32'hBEEFCAFE, "Nonce Reg 3 Check");

        // ************************************************************************
        // Test Case 6: Nonce Registers
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Nonce Registers";

        wb_transaction(32'h00000018, 32'hBEEFCAFE, 4'b1111, 1'b1, "NR0");
        wb_transaction(32'h00000018, 32'hBEEFCAFE, 4'b1111, 1'b0, "NR0");
        wb_transaction(32'h0000001C, 32'hBEEFCAFE, 4'b1111, 1'b1, "NR1");
        wb_transaction(32'h0000001C, 32'hBEEFCAFE, 4'b1111, 1'b0, "NR1");
        wb_transaction(32'h00000020, 32'hBEEFCAFE, 4'b1111, 1'b1, "NR2");
        wb_transaction(32'h00000020, 32'hBEEFCAFE, 4'b1111, 1'b0, "NR2");
        wb_transaction(32'h00000024, 32'hBEEFCAFE, 4'b1111, 1'b1, "NR3");
        wb_transaction(32'h00000024, 32'hBEEFCAFE, 4'b1111, 1'b0, "NR3");

        check_out(tb_nonce[31:0], 32'hBEEFCAFE, "Nonce Reg 0 Check");
        check_out(tb_nonce[63:32], 32'hBEEFCAFE, "Nonce Reg 1 Check");
        check_out(tb_nonce[95:64], 32'hBEEFCAFE, "Nonce Reg 2 Check");
        check_out(tb_nonce[127:96], 32'hBEEFCAFE, "Nonce Reg 3 Check");

        // ************************************************************************
        // Test Case 7: Associated Data Registers
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Associated Data Registers";

        wb_transaction(32'h00000028, 32'hBEEFCAFE, 4'b1111, 1'b1, "ADR0");
        wb_transaction(32'h00000028, 32'hBEEFCAFE, 4'b1111, 1'b0, "ADR0");
        wb_transaction(32'h0000002C, 32'hBEEFCAFE, 4'b1111, 1'b1, "ADR1");
        wb_transaction(32'h0000002C, 32'hBEEFCAFE, 4'b1111, 1'b0, "ADR1");
        wb_transaction(32'h00000030, 32'hBEEFCAFE, 4'b1111, 1'b1, "ADR2");
        wb_transaction(32'h00000030, 32'hBEEFCAFE, 4'b1111, 1'b0, "ADR2");
        wb_transaction(32'h00000034, 32'hBEEFCAFE, 4'b1111, 1'b1, "ADR3");
        wb_transaction(32'h00000034, 32'hBEEFCAFE, 4'b1111, 1'b0, "ADR3");

        check_out(tb_blockout[31:0], 32'hBEEFCAFE, "Associated Data Reg 0 Check");
        check_out(tb_blockout[63:32], 32'hBEEFCAFE, "Associated Data Reg 1 Check");

        tb_block_request = 3'd1;
        #(CLK_PERIOD / 10);
        check_out(tb_blockout[31:0], 32'hBEEFCAFE, "Associated Data Reg 2 Check");
        check_out(tb_blockout[63:32], 32'hBEEFCAFE, "Associated Data Reg 3 Check");

        // ************************************************************************
        // Test Case 8: Plaintext Data Registers
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Plaintext Data Registers";

        wb_transaction(32'h00000038, 32'hBEEFCAFE, 4'b1111, 1'b1, "PDR0");
        wb_transaction(32'h00000038, 32'hBEEFCAFE, 4'b1111, 1'b0, "PDR0");
        wb_transaction(32'h0000003C, 32'hBEEFCAFE, 4'b1111, 1'b1, "PDR1");
        wb_transaction(32'h0000003C, 32'hBEEFCAFE, 4'b1111, 1'b0, "PDR1");
        wb_transaction(32'h00000040, 32'hBEEFCAFE, 4'b1111, 1'b1, "PDR2");
        wb_transaction(32'h00000040, 32'hBEEFCAFE, 4'b1111, 1'b0, "PDR2");
        wb_transaction(32'h00000044, 32'hBEEFCAFE, 4'b1111, 1'b1, "PDR3");
        wb_transaction(32'h00000044, 32'hBEEFCAFE, 4'b1111, 1'b0, "PDR3");

        tb_block_request = 3'd2;
        #(CLK_PERIOD / 10);
        check_out(tb_blockout[31:0], 32'hBEEFCAFE, "Plaintext Data Reg 0 Check");
        check_out(tb_blockout[63:32], 32'hBEEFCAFE, "Plaintext Data Reg 1 Check");

        tb_block_request = 3'd3;
        #(CLK_PERIOD / 10);
        check_out(tb_blockout[31:0], 32'hBEEFCAFE, "Plaintext Data Reg 2 Check");
        check_out(tb_blockout[63:32], 32'hBEEFCAFE, "Plaintext Data Reg 3 Check");

        // ************************************************************************
        // Test Case 9: Ciphertext Data Registers
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Ciphertext Data Registers";

        wb_transaction(32'h00000048, 32'hBEEFCAFE, 4'b1111, 1'b1, "CDR0");
        wb_transaction(32'h00000048, 32'hBEEFCAFE, 4'b1111, 1'b0, "CDR0");
        wb_transaction(32'h0000004C, 32'hBEEFCAFE, 4'b1111, 1'b1, "CDR1");
        wb_transaction(32'h0000004C, 32'hBEEFCAFE, 4'b1111, 1'b0, "CDR1");
        wb_transaction(32'h00000050, 32'hBEEFCAFE, 4'b1111, 1'b1, "CDR2");
        wb_transaction(32'h00000050, 32'hBEEFCAFE, 4'b1111, 1'b0, "CDR2");
        wb_transaction(32'h00000054, 32'hBEEFCAFE, 4'b1111, 1'b1, "CDR3");
        wb_transaction(32'h00000054, 32'hBEEFCAFE, 4'b1111, 1'b0, "CDR3");

        tb_block_request = 3'd4;
        #(CLK_PERIOD / 10);
        check_out(tb_blockout[31:0], 32'hBEEFCAFE, "Ciphertext Data Reg 0 Check");
        check_out(tb_blockout[63:32], 32'hBEEFCAFE, "Ciphertext Data Reg 1 Check");

        tb_block_request = 3'd5;
        #(CLK_PERIOD / 10);
        check_out(tb_blockout[31:0], 32'hBEEFCAFE, "Ciphertext Data Reg 2 Check");
        check_out(tb_blockout[63:32], 32'hBEEFCAFE, "Ciphertext Data Reg 3 Check");

        tb_CTblock = 64'hABCDBEEFCAFEDCBA;
        @(negedge tb_wb_clk_i);
        tb_CTv = 1'b1;
        @(negedge tb_wb_clk_i);
        tb_CTv = 1'b0;

        wb_transaction(32'h00000048, 32'hCAFEDCBA, 4'b1111, 1'b0, "CDR0");
        wb_transaction(32'h0000004C, 32'hABCDBEEF, 4'b1111, 1'b0, "CDR1");

        tb_CTblock = 64'hABCDBEEFCAFEDCBA;
        tb_block_request = 1'b1;
        @(negedge tb_wb_clk_i);
        tb_CTv = 1'b1;
        @(negedge tb_wb_clk_i);
        tb_CTv = 1'b0;

        wb_transaction(32'h00000050, 32'hCAFEDCBA, 4'b1111, 1'b0, "CDR2");
        wb_transaction(32'h00000054, 32'hABCDBEEF, 4'b1111, 1'b0, "CDR3");



        // ************************************************************************
        // Test Case 10: Tag Registers and Sel Check
        // ************************************************************************
        tb_test_num = tb_test_num + 1;
        tb_test_case = "Tag Registers and Sel Check";

        tb_Tag = 128'hABCDBEEFCAFEDCBAABCDBEEFCAFEDCBA;
        @(negedge tb_wb_clk_i);
        tb_Tv = 1'b1;
        @(negedge tb_wb_clk_i);
        tb_Tv = 1'b0;

        wb_transaction(32'h00000058, 32'hCAFEDCBA, 4'b1111, 1'b0, "TR0");
        wb_transaction(32'h0000005C, 32'hABCDBEEF, 4'b1111, 1'b0, "TR1");
        wb_transaction(32'h00000060, 32'hCAFEDCBA, 4'b1111, 1'b0, "TR2");
        wb_transaction(32'h00000064, 32'hABCDBEEF, 4'b1111, 1'b0, "TR3");

        wb_transaction(32'h00000060, 32'hCA00DC00, 4'b1010, 1'b0, "TR2");

    end
endmodule
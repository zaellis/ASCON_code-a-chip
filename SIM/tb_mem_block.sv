`timescale 1ns / 10ps

module tb_mem_block();

    localparam  CLK_PERIOD = 10; //100MHz

    logic clk, nRST, tb_busy, tb_CTv, tb_wb_we;
    logic [6:0] tb_datalen;
    logic [4:0] tb_wb_addr;
    logic [63:0] tb_datain_ascon, tb_dataout;
    logic [31:0] tb_datain_wb;
    logic [3:0] tb_blocksize;

    integer tb_test_num;
    string tb_test_case;

    mem_block DUT(
        .clk(clk),
        .nRST(nRST),
        .busy(tb_busy),
        .CTv(tb_CTv),
        .wb_we(tb_wb_we),
        .datalen(tb_datalen),
        .wb_addr(tb_wb_addr),
        .datain_ascon(tb_datain_ascon),
        .datain_wb(tb_datain_wb),
        .blocksize(tb_blocksize),
        .dataout(tb_dataout)
    );

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

    task wb_to_mem;
        input [4:0] mem_addr;
        input [31:0] wb_dat;
        input wb_we;
        input string signal_name;
    begin
        tb_wb_addr = mem_addr;
        tb_wb_we = wb_we;
        if(wb_we) begin
            tb_datain_wb = wb_dat;
            @(posedge clk)
            #(CLK_PERIOD / 10)
            tb_wb_we = 1'b0;
        end
        else begin
            tb_datain_wb = 0;
            @(posedge clk)
            @(negedge clk)
            #((CLK_PERIOD / 10) + 0.1);
            if(wb_dat == tb_dataout[63:32]) begin // Check passed
                $info("Correct %s output during %s test case", signal_name, tb_test_case);
            end
            else begin // Check failed
                $error("Incorrect %s output during %s test case. Expecting %h Actual %h", signal_name, tb_test_case, wb_dat, tb_dataout[63:32]);
            end
        end
    end
    endtask

    task ascon_to_mem;
        input [6:0] datalen;
    begin
        int i;
        int temp_addr;
        int rounds; 
        
        rounds = datalen[6:3];
        tb_datalen = datalen;

        @(posedge clk);
        tb_busy = 1'b1;
        @(posedge clk);
        @(posedge clk);
        
        for(i = 0; i < rounds; i++) begin
            @(posedge clk);
            @(negedge clk)
            #((CLK_PERIOD / 10) + 0.1);
            if(tb_dataout == {56'hABCDBEEFCAFEDC, i[7:0]})
                $info("Correct Plaintext Block for Block %d", i);
            else
                $error("Incorrect Plaintext Block %d. Expecting %h Actual %h", i, {56'hABCDBEEFCAFEDC, i[7:0]}, tb_dataout);
            @(posedge clk);
            @(posedge clk);
            tb_CTv = 1'b1;
            tb_datain_ascon = {56'hDCBABEEFCAFEAB, i[7:0]};
            @(posedge clk);
            tb_CTv = 1'b0;
            @(posedge clk);
            @(posedge clk);
        end

        tb_busy = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        for(i = 0; i < rounds; i++) begin
            @(posedge clk);
            temp_addr = 2 * i;
            $info("Cipher Block %d", i);
            wb_to_mem(temp_addr[4:0], {24'hCAFEAB, i[7:0]}, 1'b0, "Cipher_Blocks");

            @(posedge clk);
            temp_addr += 1;
            wb_to_mem(temp_addr[4:0], 32'hDCBABEEF, 1'b0, "Cipher_Blocks");

            @(posedge clk);
            @(posedge clk);

        end
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
        nRST = 1;
        tb_busy = 0;
        tb_CTv = 0;
        tb_wb_we = 0;
        tb_datalen = '0;
        tb_wb_addr = '0;
        tb_datain_ascon = '0;
        tb_datain_wb = '0;

        tb_test_num = 1;
        tb_test_case = "Basic Read/Write";
        
        reset_dut();
        @(posedge clk);

        wb_to_mem(5'd0, 32'hBEEFCAFE, 1'b1, "MemAddr_0");
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        wb_to_mem(5'd0, 32'hBEEFCAFE, 1'b0, "MemAddr_0");

        tb_test_num = 1;
        tb_test_case = "Read after Write hazard";
        wb_to_mem(5'd1, 32'hBEEFCAFE, 1'b1, "MemAddr_1");
        wb_to_mem(5'd1, 32'hBEEFCAFE, 1'b0, "MemAddr_1");

        tb_test_num += 1;
        tb_test_case = "4 PT Block ASCON sim";
        wb_to_mem(5'd0, 32'hCAFEDC00, 1'b1, "MemAddr_0");
        wb_to_mem(5'd1, 32'hABCDBEEF, 1'b1, "MemAddr_1");
        wb_to_mem(5'd2, 32'hCAFEDC01, 1'b1, "MemAddr_2");
        wb_to_mem(5'd3, 32'hABCDBEEF, 1'b1, "MemAddr_3");
        wb_to_mem(5'd4, 32'hCAFEDC02, 1'b1, "MemAddr_4");
        wb_to_mem(5'd5, 32'hABCDBEEF, 1'b1, "MemAddr_5");
        wb_to_mem(5'd6, 32'hCAFEDC03, 1'b1, "MemAddr_6");
        wb_to_mem(5'd7, 32'hABCDBEEF, 1'b1, "MemAddr_7");
        ascon_to_mem(7'b0100000);
        

    end
endmodule
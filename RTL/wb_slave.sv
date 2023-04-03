module wb_slave(
    //Wishbone interface
    input logic wb_clk_i,
    input logic wb_rst_i,
    input logic [31:0] wb_adr_i,
    input logic [31:0] wb_dat_i,
    input logic [3:0] wb_sel_i,
    input logic wb_we_i,
    input logic wb_cyc_i,
    input logic wb_stb_i,
    output logic wb_ack_o,      
    output logic [31:0] wb_dat_o,
    //ASCON interface
    input logic [2:0] state,
    input logic [127:0] Tag,
    input logic [63:0] CTblock,
    input logic CTv,
    input logic Tv,
    input logic block_request,
    output logic start,
    output logic busy,
    output logic [1:0] mode,
    output logic [127:0] key,
    output logic [127:0] nonce,
    output logic [63:0] blockout,
    output logic [7:0] datalen,
    output logic [4:0] AD_len,
    output logic [31:0] datain_wb,
    output logic [4:0] wb_addr,
    output logic mem_we
);

    logic [31:0] regs [17:0];
    logic [31:0] next_regs [17:0];
    logic CTBlock_location;

    logic [31:0] raw_dat_o;
    logic [31:0] mask;

    logic next_ack;
    logic [5:0] wb_addr_intermediate;

    assign mask[31:24] = {8{wb_sel_i[3]}};
    assign mask[23:16] = {8{wb_sel_i[2]}};
    assign mask[15:8] = {8{wb_sel_i[1]}};
    assign mask[7:0] = {8{wb_sel_i[0]}};

    assign busy = regs[0][3];
    assign start = regs[1][15];
    assign mode = regs[1][14:13];
    assign AD_len = regs[1][12:8];
    assign datalen = regs[1][7:0];
    assign key[31:0] = regs[2];
    assign key[63:32] = regs[3];
    assign key[95:64] = regs[4];
    assign key[127:96] = regs[5];
    assign nonce[31:0] = regs[6];
    assign nonce[63:32] = regs[7];
    assign nonce[95:64] = regs[8];
    assign nonce[127:96] = regs[9];

    assign datain_wb = wb_dat_i & mask;
    assign wb_addr = wb_addr_intermediate[4:0];

    always_ff @(posedge wb_clk_i, posedge wb_rst_i) begin
        if(wb_rst_i == 1'b1) begin
            regs[0] <= '0;
            regs[1] <= '0;
            regs[2] <= '0;
            regs[3] <= '0;
            regs[4] <= '0;
            regs[5] <= '0;
            regs[6] <= '0;
            regs[7] <= '0;
            regs[8] <= '0;
            regs[9] <= '0;
            regs[10] <= '0;
            regs[11] <= '0;
            regs[12] <= '0;
            regs[13] <= '0;
            regs[14] <= '0;
            regs[15] <= '0;
            regs[16] <= '0;
            regs[17] <= '0;
            CTBlock_location <= '0;
            wb_ack_o <= '0;
            wb_dat_o <= '0;
        end
        else begin
            regs[0] <= next_regs[0];
            regs[1] <= next_regs[1];
            regs[2] <= next_regs[2];
            regs[3] <= next_regs[3];
            regs[4] <= next_regs[4];
            regs[5] <= next_regs[5];
            regs[6] <= next_regs[6];
            regs[7] <= next_regs[7];
            regs[8] <= next_regs[8];
            regs[9] <= next_regs[9];
            regs[10] <= next_regs[10];
            regs[11] <= next_regs[11];
            regs[12] <= next_regs[12];
            regs[13] <= next_regs[13];
            regs[14] <= next_regs[14];
            regs[15] <= next_regs[15];
            regs[16] <= next_regs[16];
            regs[17] <= next_regs[17];
            if(start)
                CTBlock_location <= 1'b0;
            if(CTv)
                CTBlock_location <= 1'b1;
            wb_ack_o <= next_ack;
            wb_dat_o <= raw_dat_o & mask;
        end
    end

    always_comb begin
        next_regs[0] = regs[0];
        next_regs[1] = regs[1];
        next_regs[2] = regs[2];
        next_regs[3] = regs[3];
        next_regs[4] = regs[4];
        next_regs[5] = regs[5];
        next_regs[6] = regs[6];
        next_regs[7] = regs[7];
        next_regs[8] = regs[8];
        next_regs[9] = regs[9];
        next_regs[10] = regs[10];
        next_regs[11] = regs[11];
        next_regs[12] = regs[12];
        next_regs[13] = regs[13];
        next_regs[14] = regs[14];
        next_regs[15] = regs[15];
        next_regs[16] = regs[16];
        next_regs[17] = regs[17];
        blockout = '0;
        raw_dat_o = '0;
        next_ack = '0;
        wb_addr_intermediate = '0;
        mem_we = 1'b1;

        if(wb_cyc_i & wb_stb_i) begin
            if(wb_adr_i[7:2] < 18) begin
                next_ack = 1'b1;
                if(wb_we_i)
                    next_regs[wb_adr_i[6:2]] = wb_dat_i & mask;
                else
                    raw_dat_o = regs[wb_adr_i[6:2]] & mask;
            end
            else begin
                next_ack = ~busy;
                mem_we = ~wb_we_i;
                wb_addr_intermediate = wb_adr_i[7:2] - 6'd18;              
            end
                

        end

        //make sure this stuff is always the case (to preserve read only and reserved bits)
        next_regs[0][2:0] = state;
        next_regs[0][3] = (state == '0) ? 1'b0 : 1'b1;

        if(start)
            next_regs[1][15] = 1'b0; //make sure start is only active for 1 clock cycle

        if(block_request)
            blockout = {regs[13], regs[12]};
        else
            blockout = {regs[11], regs[10]};

        if(Tv == 1'b1) begin
            next_regs[14] = Tag[31:0];
            next_regs[15] = Tag[63:32];
            next_regs[16] = Tag[95:64];
            next_regs[17] = Tag[127:96];
        end

        //This should stay at the bottom. cipher block back from core overides a write from the user

        next_regs[0][31:4] = '0; //hopefully this means FF won't be synthesized for these bits
        next_regs[1][31:16] = '0;
    end
endmodule
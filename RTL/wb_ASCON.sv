module wb_ASCON(
    input logic clk,
    input logic nRST,
    input logic [31:0] wb_adr_i,
    input logic [31:0] wb_dat_i,
    input logic [3:0] wb_sel_i,
    input logic wb_we_i,
    input logic wb_cyc_i,
    input logic wb_stb_i,
    output logic wb_ack_o,      
    output logic [31:0] wb_dat_o
);

    logic [2:0] state;
    logic [127:0] Tag;
    logic [63:0] CTblock;
    logic CTv;
    logic Tv;
    logic block_request;
    logic start;
    logic [1:0] mode;
    logic [127:0] key;
    logic [127:0] nonce;
    logic [6:0] datalen_packet;
    logic [3:0] AD_len;

    logic [31:0] datain_wb;

    logic [4:0] wb_addr;

    logic AD_cntrl;
    logic [3:0] datalen_AD, blocksize, datalen;
    logic [63:0] dataout_mem, blockout, blockin;

    always_comb begin
        if(AD_cntrl) begin
            blockin = blockout;
            datalen = datalen_AD;
        end
        else begin
            blockin = dataout_mem;
            datalen = blocksize;
        end
    end

    wb_slave wbs(
        .wb_clk_i(clk),
        .wb_rst_i(~nRST),
        .wb_adr_i(wb_adr_i),
        .wb_dat_i(wb_dat_i),
        .wb_sel_i(wb_sel_i),
        .wb_we_i(wb_we_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_stb_i(wb_stb_i),
        .wb_ack_o(wb_ack_o),      
        .wb_dat_o(wb_dat_o),
        .state(state),
        .Tag(Tag),
        .CTblock(CTblock),
        .CTv(CTv),
        .Tv(Tv),
        .block_request(block_request),
        .start(start),
        .busy(busy),
        .mode(mode),
        .key(key),
        .nonce(nonce),
        .blockout(blockout),
        .datalen(datalen_packet),
        .AD_len(AD_len),
        .datain_wb(datain_wb),
        .wb_addr(wb_addr),
        .mem_we(mem_we)
    );

    ASCON_AEAD ascon_core(
        .clk(clk),
        .nRST(nRST),
        .start(start),
        .mode(mode),
        .key(key),
        .nonce(nonce),
        .blockin(blockin),
        .datalen(datalen),
        .Tag(Tag),
        .CTblock(CTblock),
        .CTv(CTv),
        .Tv(Tv),
        .AD_read(AD_read),
        .state(state)
    );

    mem_block mb(
        .clk(clk),
        .nRST(nRST),
        .busy(busy),
        .CTv(CTv),
        .wb_we(mem_we),
        .datalen(datalen_packet),
        .wb_addr(wb_addr),
        .datain_ascon(CTblock),
        .datain_wb(datain_wb),
        .blocksize(blocksize),
        .dataout(dataout_mem)
    );

    AD_loader adl(
        .clk(clk),
        .nRST(nRST),
        .busy(busy),
        .AD_read(AD_read),
        .AD_len(AD_len),
        .block_request(block_request),
        .AD_cntrl(AD_cntrl),
        .datalen(datalen_AD)
    );


endmodule
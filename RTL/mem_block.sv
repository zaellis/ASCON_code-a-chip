module mem_block(
    input logic clk,
    input logic nRST,
    input logic busy,
    input logic CTv,
    input logic wb_we,
    input logic [7:0] datalen,
    input logic [4:0] wb_addr,
    input logic [63:0] datain_ascon,
    input logic [31:0] datain_wb,
    output logic [3:0] blocksize,
    output logic [63:0] dataout
);

    logic we;
    logic [4:0] mem_addr;
    logic [31:0] mem_dataout, mem_datain;

    mem_ctrl mc(
        .clk(clk),
        .nRST(nRST),
        .busy(busy),
        .CTv(CTv),
        .wb_we(wb_we),
        .datalen(datalen),
        .wb_addr(wb_addr),
        .datain_ascon(datain_ascon),
        .datain_wb(datain_wb),
        .mem_dataout(mem_dataout),
        .we(we),
        .blocksize(blocksize),
        .dataout(dataout),
        .mem_addr(mem_addr),
        .mem_datain(mem_datain)
    );

    sky130_sram_1r1w_32x32_32 sram(
    `ifdef USE_POWER_PINS
        vccd1,
        vssd1,
    `endif
    // Port 0: W
        .clk0(clk),
        .csb0(we),
        .addr0(mem_addr),
        .din0(mem_datain),
    // Port 1: R
        .clk1(clk),
        .csb1(~we),
        .addr1(mem_addr),
        .dout1(mem_dataout)
    );

endmodule
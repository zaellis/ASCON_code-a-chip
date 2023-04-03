module mem_ctrl(
    input logic clk,
    input logic nRST,
    input logic busy,
    input logic CTv,
    input logic wb_we,
    input logic [7:0] datalen,
    input logic [4:0] wb_addr,
    input logic [63:0] datain_ascon,
    input logic [31:0] datain_wb,
    input logic [31:0] mem_dataout,
    output logic we,
    output logic [3:0] blocksize,
    output logic [63:0] dataout,
    output logic [4:0] mem_addr,
    output logic [31:0] mem_datain
);

    typedef enum logic [2:0] { 
        idle,
        read_0,
        read_1,
        write_0,
        write_1,
        stall
    } state_t;

    state_t state, next_state;

    logic [31:0] read_regs, next_read_regs;
    logic [31:0] write_regs, next_write_regs;
    logic [4:0] addr_cntr, next_count;
    logic last_addr;

    assign dataout = {mem_dataout, read_regs};
    assign last_addr = (({1'b0, addr_cntr[4:1]} + 5'd1) == {1'b0, datalen[7:4]}) ? 1'b1 : 1'b0;

    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 1'b0) begin
            state <= idle;
            read_regs <= '0;
            write_regs <= '0;
            addr_cntr <= '0;
        end
        else begin
            state <= next_state;
            read_regs <= next_read_regs;
            write_regs <= next_write_regs;
            addr_cntr <= next_count;
        end
    end

    always_comb begin
        if(busy)
            next_state = state;
        else
            next_state = idle;
        next_read_regs = read_regs;
        next_write_regs = write_regs;
        next_count = addr_cntr;

        we = 1'b1; //this is an active low signal so we = 1 means read
        mem_datain = '0;
        mem_addr = '0;

        blocksize = 4'd1;

        case(state)
            idle: begin
                we = wb_we;
                mem_addr = wb_addr;
                mem_datain = datain_wb[31:0];
                next_count = 0;
                if(busy)
                    next_state = read_0;
            end
            read_0: begin
                mem_addr = addr_cntr;
                next_count = addr_cntr + 1;
                next_state = read_1;
            end
            read_1: begin
                next_read_regs = mem_dataout;
                mem_addr = addr_cntr;
                next_state = write_0;
            end
            write_0: begin
                mem_addr = addr_cntr;
                next_write_regs = datain_ascon[63:32];
                if(CTv) begin
                    blocksize = (last_addr == 1'b1) ? datalen[3:0] : 4'd8;
                    we = 1'b0;
                    mem_addr = addr_cntr - 1;
                    mem_datain = datain_ascon[31:0];
                    next_state = write_1;
                end
            end
            write_1: begin
                we = 1'b0;
                mem_addr = addr_cntr;
                mem_datain = write_regs;
                next_count = addr_cntr + 1;
                if(last_addr)
                    next_state = stall;
                else
                    next_state = read_0;
            end
            stall: begin
                blocksize = '0;
            end
        endcase
    end

endmodule
module AD_loader(
    input logic clk,
    input logic nRST,
    input logic busy,
    input logic AD_read,
    input logic [3:0] AD_len,
    output logic block_request,
    output logic AD_cntrl,
    output logic [3:0] datalen
);

    typedef enum logic [2:0] { 
        idle,
        block_0,
        block_1,
        stall
    } state_t;

    state_t state, next_state;

    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == '0) begin
            state <= idle;
        end
        else begin
            state <= next_state;
        end
    end

    always_comb begin

        AD_cntrl = 1'b1;
        block_request = 1'b0;

        if(busy)
            next_state = state;
        else
            next_state = idle;
        
        case(state)
            idle: begin
                if(busy)
                    next_state = block_0;
            end
            block_0: begin
                if(AD_len[3] == 1'b1)
                    datalen = 4'd8;
                else
                    datalen = AD_len[3:0];
                if(AD_read) begin
                    next_state = block_1;
                    AD_cntrl = AD_len[3];
                end
            end
            block_1: begin
                AD_cntrl = AD_len[3];
                block_request = 1'b1;
                if(AD_len[2:0] == '0)
                    datalen = 4'd8;
                else
                    datalen = {1'b0, AD_len[2:0]}; 
                if(AD_read)
                    datalen = '0;
                if(~AD_len[3] || AD_read)
                    next_state = stall;
            end
            stall: begin
                AD_cntrl = 1'b0;
            end
        endcase
    end

endmodule
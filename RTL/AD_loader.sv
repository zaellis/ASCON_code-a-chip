module AD_loader(
    input logic clk,
    input logic nRST,
    input logic busy,
    input logic AD_read,
    input logic [4:0] AD_len,
    output logic block_request,
    output logic AD_cntrl,
    output logic [3:0] datalen
);

    typedef enum logic [2:0] { 
        idle,
        block_0,
        block_1,
        block_2,
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
        datalen = '0;

        if(busy)
            next_state = state;
        else
            next_state = idle;
        
        case(state)
            idle: begin
                if(busy && (AD_len != 0))
                    next_state = block_0;
            end
            block_0: begin
                if(AD_len[4] == 1'b1)
                    datalen = 4'd8;
                else
                    datalen = AD_len[3:0];
                if(AD_read) begin
                    next_state = block_1;
                end
            end
            block_1: begin
                AD_cntrl = AD_len[4] | AD_len[3];
                block_request = 1'b1; 
                datalen = 4'd8;
                if(AD_read) begin
                    if(AD_len[4] & AD_len[3]) begin
                        next_state = block_2;
                        datalen = AD_len[3:0];
                    end
                    else begin
                        next_state = stall;
                        datalen = {1'b0, AD_len[2:0]};
                    end
                end
                if(~AD_cntrl)
                    next_state = stall;
            end
            block_2: begin
                AD_cntrl = 1'b1;
                datalen = 4'd8;
                if(AD_read) begin
                    datalen = '0;
                    next_state = stall;
                end
            end
            stall: begin
                AD_cntrl = 1'b0;
            end
        endcase
    end

endmodule
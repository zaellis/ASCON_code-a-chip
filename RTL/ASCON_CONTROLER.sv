module ASCON_CONTROLER #(
    parameter A = 12,
    parameter B = 6
)
(
    input logic clk,
    input logic nRST,
    input logic start,
    input logic [1:0] mode,
    input logic [127:0] key,
    input logic [127:0] nonce,
    input logic [3:0] datalen,
    input logic [63:0] blockin,
    input logic [63:0] Xo0,
    input logic [63:0] Xo1,
    input logic [63:0] Xo2,
    input logic [63:0] Xo3,
    input logic [63:0] Xo4,
    output logic [127:0] Tag,
    output logic [63:0] CTblock,
    output logic CTv,
    output logic Tv,
    output logic AD_read,
    output logic [2:0] state_out,
    output logic [1:0] rcmode,
    output logic [3:0] rcinit,
    output logic [63:0] Xi0,
    output logic [63:0] Xi1,
    output logic [63:0] Xi2,
    output logic [63:0] Xi3,
    output logic [63:0] Xi4
);
    
    typedef enum logic [2:0] {
        idle,
        intialize,
        AD,
        PT,
        CT,
        finalize
    } state_t;

    state_t state, next_state;
    logic [3:0] count, next_count;
    logic [3:0] last_len;
    logic [63:0] pado, pado2;

    assign state_out = state;

    assign Tag = {Xo3,Xo4} ^ key;
    assign CTblock = Xo0 ^ pado; 
    ASCONpadding asconpad1 (blockin,datalen,pado);
    ASCONpadding asconpad2 (CTblock,datalen,pado2);

    always_ff @(posedge clk, negedge nRST) begin
        if(nRST == 0) begin
            state <= idle;
            count <= '0;
            last_len <= '0;
        end
        else begin
            state <= next_state;
            count <= next_count;
            last_len <= datalen;
        end
    end

    always_comb begin
        next_state = state;
        next_count = count + 1;

        CTv = '0;
        Tv = '0;
        AD_read = 1'b0;
        rcmode = '0;
        rcinit = '0;
        Xi0 = '0;
        Xi1 = '0;
        Xi2 = '0;
        Xi3 = '0;
        Xi4 = '0;

        case(state)
            idle: begin
                Xi0 = 64'h80400c0600000000;
                Xi1 = key[127:64];
                Xi2 = key[63:0];
                Xi3 = nonce[127:64];
                Xi4 = nonce[63:0];
                rcmode = 2'd2;
                if(start == 1) begin
                    next_state = intialize;
                    next_count = 1;
                end
            end
            intialize: begin
                rcmode = 2'd1;
                Xi0 = Xo0;
                Xi1 = Xo1;
                Xi2 = Xo2;
                Xi3 = Xo3;
                Xi4 = Xo4;
                if(count == A) begin
                    next_count = 1;
                    rcmode = 2'd2;
                    Xi3 = Xo3 ^ key[127:64];
                    case(mode)
                        2'd0: begin
                            Xi4 = Xo4 ^ key[63:0]^1;
                            CTv = (datalen == '0) ? 1'b0 : 1'b1;
                            if(datalen == 4'd8) begin
                                Xi0 = blockin;
                                next_state = CT;
                                rcinit = 4'b0110;
                            end
                            else begin
                                Xi0 = pado2 ^ Xo0;;
                                next_state = finalize;
                                Xi1 = Xo1 ^ key[127:64];
                                Xi2 = Xo2 ^ key[63:0];
                            end
                        end
                        2'd1: begin
                            Xi0 = CTblock;
                            Xi4 = Xo4 ^ key[63:0]^1;
                            CTv = 1'b1;
                            if(datalen == 4'd8) begin
                                next_state = PT;
                                rcinit = 4'b0110;
                            end
                            else begin
                                next_state = finalize;
                                Xi1 = Xo1 ^ key[127:64];
                                Xi2 = Xo2 ^ key[63:0] ;
                            end
                        end
                        2'd2: begin
                            AD_read = 1'b1;
                            next_state = AD;
                            rcinit = 4'b0110;
                            Xi0 = CTblock; //ADblock ^ Xo0;
                            Xi4 = Xo4 ^ key[63:0];
                        end
                        2'd3: begin
                            AD_read = 1'b1;
                            next_state = AD;
                            rcinit = 4'b0110;
                            Xi0 = CTblock; //ADblock ^ Xo0;
                            Xi4 = Xo4 ^ key[63:0];
                        end
                    endcase
                end
            end
            AD: begin
                rcmode = 2'd1;
                Xi0 = Xo0;
                Xi1 = Xo1;
                Xi2 = Xo2;
                Xi3 = Xo3;
                Xi4 = Xo4;
                if(count == B) begin
                    next_count = 1;
                    rcmode = 2'd2;
                    AD_read = 1'b1;
                    if(last_len == 4'd8) begin //this needs to change to last_len (registered)
                        rcinit = 4'b0110;
                        Xi0 = CTblock;
                    end
                    else if(mode[0] == 1) begin
                        CTv = 1'b1;
                        Xi0 = CTblock;
                        Xi4 = Xo4 ^ 1;
                        if(datalen == 4'd8) begin
                            rcinit = 4'b0110;
                            next_state = PT;
                        end
                        else begin
                            rcinit = 4'b0000;
                            Xi1 = Xo1 ^ key[127:64];
                            Xi2 = Xo2 ^ key[63:0] ;
                            next_state = finalize;
                        end
                    end
                    else begin
                        CTv = (datalen == '0) ? 1'b0 : 1'b1;
                        Xi4 = Xo4 ^ 1;
                        if(datalen == 4'd8) begin
                            Xi0 = blockin;
                            rcinit = 4'b0110;
                            next_state = CT;
                        end
                        else begin
                            rcinit = 4'b0000;
                            Xi0 = pado2 ^ Xo0;;
                            Xi1 = Xo1 ^ key[127:64];
                            Xi2 = Xo2 ^ key[63:0];
                            next_state = finalize;
                        end
                    end
                end
            end
            PT: begin
                rcmode = 2'd1;
                Xi0 = Xo0;
                Xi1 = Xo1;
                Xi2 = Xo2;
                Xi3 = Xo3;
                Xi4 = Xo4;
                if(count == B) begin
                    next_count = 1;
                    rcmode = 2'd2;
                    Xi0 = CTblock;
                    CTv = (datalen == '0) ? 1'b0 : 1'b1;
                    if(datalen == 4'd8) begin
                        rcinit = 4'b0110;
                    end
                    else begin
                        rcinit = 4'b0000;
                        Xi1 = Xo1 ^ key[127:64];
                        Xi2 = Xo2 ^ key[63:0];
                        next_state = finalize;
                    end
                end
            end
            CT: begin
                rcmode = 2'd1;
                Xi0 = Xo0;
                Xi1 = Xo1;
                Xi2 = Xo2;
                Xi3 = Xo3;
                Xi4 = Xo4;
                if(count == B) begin
                    next_count = 1;
                    rcmode = 2'd2;
                    CTv = (datalen == '0) ? 1'b0 : 1'b1;
                    if(datalen == 4'd8) begin
                        Xi0 = blockin;
                        rcinit = 4'b0110;
                    end
                    else begin
                        rcinit = 4'b0000;
                        Xi0 = pado2 ^ Xo0;
                        Xi1 = Xo1 ^ key[127:64];
                        Xi2 = Xo2 ^ key[63:0];
                        next_state = finalize;
                    end
                end
            end
            finalize: begin
                rcmode = 2'd1;
                Xi0 = Xo0;
                Xi1 = Xo1;
                Xi2 = Xo2;
                Xi3 = Xo3;
                Xi4 = Xo4;
                if(count == A) begin
                    Tv = 1;
                    next_state = idle;
                end
            end
        endcase
    end

endmodule
module ASCONpadding(
    input logic [63:0] Ti,
    input [3:0] Tlen,
    output reg [63:0] To
);

    always_comb begin

        case (Tlen)
            4'd0: To={1'b1,63'b0};
            4'd1: To={Ti[63:56],1'b1,55'b0};
            4'd2: To={Ti[63:48],1'b1,47'b0};
            4'd3: To={Ti[63:40],1'b1,39'b0};
            4'd4: To={Ti[63:32],1'b1,31'b0};
            4'd5: To={Ti[63:24],1'b1,23'b0};
            4'd6: To={Ti[63:16],1'b1,15'b0};
            4'd7: To={Ti[63:8],1'b1,7'b0};
            4'd8: To={Ti[63:0]};
            default: To={Ti[63:0]};
        endcase
    end
endmodule

module ASCON_DATAPATH #(
    parameter UNROLL = 1
)
(
    input logic clk,
    input logic nRST,
    input logic [1:0] rcmode,
    input logic [3:0] constti,
    input logic [63:0] Xi0,
    input logic [63:0] Xi1,
    input logic [63:0] Xi2,
    input logic [63:0] Xi3,
    input logic [63:0] Xi4,
    output logic [63:0] Xo0,
    output logic [63:0] Xo1,
    output logic [63:0] Xo2,
    output logic [63:0] Xo3,
    output logic [63:0] Xo4
);
    
    logic [3:0] constt;
    logic [63:0] Xreg0,Xreg1,Xreg2,Xreg3,Xreg4;

    logic [UNROLL:0] [63:0] Xm0,Xm1,Xm2,Xm3,Xm4;
    logic [UNROLL - 1:0] [3:0] constt_int;

    ASCON_ROUND_CONSTANT asconRC1(
        .clk(clk),.nRST(nRST),.rcmode(rcmode),
        .constti(constti),
        .constt(constt)
    );

    assign Xm0[0] = Xreg0;
    assign Xm1[0] = Xreg1;
    assign Xm2[0] = Xreg2;
    assign Xm3[0] = Xreg3;
    assign Xm4[0] = Xreg4;

    assign Xo0 = Xm0[UNROLL];
    assign Xo1 = Xm1[UNROLL];
    assign Xo2 = Xm2[UNROLL];
    assign Xo3 = Xm3[UNROLL];
    assign Xo4 = Xm4[UNROLL];

    genvar i;
    generate    
        for(i = 0; i < UNROLL; i++) begin  
            assign constt_int[i] = constt + i;
            ASCON_ROUND_FUNCTION asconRFI(
                Xm0[i],Xm1[i],Xm2[i],Xm3[i],Xm4[i], 
                {~constt_int[i], constt_int[i]}, 
                Xm0[i+1],Xm1[i+1],Xm2[i+1],Xm3[i+1],Xm4[i+1] 
            );
        end
    endgenerate
    
    always_ff @(posedge clk , negedge nRST) begin
        if (nRST == 1'b0) begin
            Xreg0 = '0;
            Xreg1 = '0;
            Xreg2 = '0;
            Xreg3 = '0;
            Xreg4 = '0; 
        end
        else begin
            Xreg0 = Xi0;
            Xreg1 = Xi1;
            Xreg2 = Xi2;
            Xreg3 = Xi3;
            Xreg4 = Xi4;
        end
    end
    
endmodule

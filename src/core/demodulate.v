// Error demodulation block.
`include "DEF.v"

module demodulate(
    rst,
    ena,
    clk,
    adin,
    counter,
    state,
    dRotateOut,
    dVrefOut,
    counterN,
    N,
    tauCounter,
    updown,
    random,
    cfg_sft_pd,
    cfg_delayAD,
    cfg_delay1,
    cfg_delay2,
    cfg_reserveN
);
input rst;
input ena;
input clk;
input [11:0] adin;
input [8:0] counter;
input [1:0] state;
output [31:0] dRotateOut;
output [31:0] dVrefOut;
output random;
input [9:0] counterN;
input [9:0] N;
input [11:0] tauCounter;
input updown;
input [11:0] cfg_sft_pd;
input [7:0] cfg_delayAD;
input [7:0] cfg_delay1;
input [7:0] cfg_delay2;
input [7:0] cfg_reserveN;

reg random;
reg randomPre;
reg [31:0] dRotateOut;
reg [31:0] dVrefOut;

wire [9:0] delayADw;
wire [9:0] delay1w;
wire [9:0] delay2w;
wire [9:0] reserveNw;
wire [9:0] delaySum;
wire [9:0] halfN;

assign delayADw = {2'b00, cfg_delayAD};
assign delay1w = {2'b00, cfg_delay1};
assign delay2w = {2'b00, cfg_delay2};
assign reserveNw = {2'b00, cfg_reserveN};
assign delaySum = delayADw + delay1w;
assign halfN = {1'b0, N[9:1]};

always @ (posedge clk or negedge rst)
begin
    if (!rst)
        dRotateOut <= 32'b0;
    else if (ena)
    begin
        if (counter == 1 && state[0] == 1'b0)
            dRotateOut <= 0;
        else if (tauCounter == 12'd2 || tauCounter == 12'd3)
            dRotateOut <= dRotateOut;
        else
        begin
            if (counterN > delaySum && counterN <= halfN + delayADw - 1'b1)
            begin
                if (state[1] == 0)
                    dRotateOut <= dRotateOut + adin;
                else if (state[1] == 1)
                    dRotateOut <= dRotateOut - adin;
            end
            else if (counter > delayADw + delay2w && counter <= halfN - reserveNw && state[0] == 1)
            begin
                if (state[1] == 0)
                    dRotateOut <= dRotateOut - adin;
                else if (state[1] == 1)
                    dRotateOut <= dRotateOut + adin;
            end
        end
    end
end

always @ (posedge clk or negedge rst)
begin
    if (!rst)
        dVrefOut <= 32'b0;
    else if (ena)
    begin
        if (counter == 1 && state == 2'b00)
            dVrefOut <= 0;
        else if (tauCounter == 12'd2 || tauCounter == 12'd3)
            dVrefOut <= dVrefOut;
        else
        begin
            if (counterN > delaySum && counterN <= halfN + delayADw - 1'b1)
                dVrefOut <= dVrefOut + adin;
            else if (counter > delayADw + delay2w && counter <= halfN - reserveNw && state[0] == 1)
                dVrefOut <= dVrefOut - adin;
        end
    end
end

always @ (posedge clk or negedge rst)
begin
    if (!rst)
    begin
        randomPre <= 1'b0;
        random <= 1'b0;
    end
    else if (ena)
    begin
        if (counter > delaySum && counter <= halfN - 4)
            randomPre <= randomPre + adin[0];
        else if (counter == halfN - 3 && state == 2'b11 && tauCounter == cfg_sft_pd)
            random <= randomPre;
    end
end

endmodule

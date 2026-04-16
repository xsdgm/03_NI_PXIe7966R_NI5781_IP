`include "DEF.v"

// Phase-step waveform generator used by the first loop.

// 0 ~ 3.1PI
`define PI 21140

// 0.9PI
`define PIa 19026
`define PIb 23254
`define PIbpa 4228
`define PIbpPI 2114

module ladhpi(rst,ladena1,ladena2,clk,ladin,state,ladout,tauCounter,updown,random);
input rst;
input ladena1;
input ladena2;
input [31:0] ladin;
input clk;
input [1:0] state;
input random;
output [15:0] ladout;
output [11:0] tauCounter;
output updown;

reg [31:0] ladreg;
reg [15:0] ladout;
reg [31:0] ladtmp;
reg [11:0] tauCounter;
reg updown;

// Count phase-step interval.
always @(posedge clk or negedge rst)
begin
    if(!rst)
        tauCounter <= 0;
    else if(ladena1)
    begin
        if(state == 2'b01 && tauCounter[0] != 1'b0)
            tauCounter[0] <= 1'b1;
        else if(state[0] == 1'b1)
        begin
            if(tauCounter >= 12'd`SFT_PD)
                tauCounter <= 1'b0;
            else
                tauCounter <= tauCounter + 1'b1;
        end
    end
end

// Decide the direction of the periodic phase step.
always @(posedge clk or negedge rst)
begin
    if(!rst)
        updown <= 0;
    else if(tauCounter == 12'd`SFT_PD && ladena1 && state[0] == 1'b1)
        updown <= random;
end

// Combine ladder value, error term and periodic phase step.
always @(ladreg or ladin or updown or tauCounter)
begin
    if(updown == 0 && tauCounter == 12'd1)
        ladtmp = ladreg + ladin + {16'd`PIbpPI,11'b0};
    else if(updown == 1 && tauCounter == 12'd1)
        ladtmp = ladreg + ladin - {16'd`PIbpPI,11'b0};
    else if(updown == 0 && tauCounter == 12'd2)
        ladtmp = ladreg + ladin + {16'd`PIbpPI,11'b0};
    else if(updown == 1 && tauCounter == 12'd2)
        ladtmp = ladreg + ladin - {16'd`PIbpPI,11'b0};
    else
        ladtmp = ladreg + ladin;
end

// Keep the pure ladder waveform wrapped into the allowed range.
always @(posedge clk or negedge rst)
begin
    if(!rst)
        ladreg <= 32'b0;
    else if(ladena1 && state[0] == 1'b1)
    begin
        if (ladtmp[31] == 0 && ladtmp[31:11] >= 21'd253680)
            ladreg <= ladtmp - {19'd253680,11'b0};
        else if(ladtmp[31] == 0 && ladtmp[31:11] >= 21'd211400)
            ladreg <= ladtmp - {19'd211400,11'b0};
        else if(ladtmp[31] == 0 && ladtmp[31:11] >= 21'd169120)
            ladreg <= ladtmp - {19'd169120,11'b0};
        else if(ladtmp[31] == 0 && ladtmp[31:11] >= 21'd126840)
            ladreg <= ladtmp - {19'd126840,11'b0};
        else if(ladtmp[31] == 0 && ladtmp[31:11] >= 21'd84560)
            ladreg <= ladtmp - {19'd84560,11'b0};
        else if(ladtmp[31] == 0 && ladtmp[31:11] >= 21'd42280)
            ladreg <= ladtmp - {19'd42280,11'b0};
        else if(ladtmp[31] == 1 && ladtmp[31:11] < 21'h1CC638)
            ladreg <= ladtmp + {19'd253680,11'b0};
        else if(ladtmp[31] == 1 && ladtmp[31:11] < 21'h1D6B60)
            ladreg <= ladtmp + {19'd211400,11'b0};
        else if(ladtmp[31] == 1 && ladtmp[31:11] < 21'h1E1088)
            ladreg <= ladtmp + {19'd169120,11'b0};
        else if(ladtmp[31] == 1 && ladtmp[31:11] < 21'h1EB5B0)
            ladreg <= ladtmp + {19'd126840,11'b0};
        else if(ladtmp[31] == 1 && ladtmp[31:11] < 21'h1F5AD8)
            ladreg <= ladtmp + {19'd84560,11'b0};
        else if(ladtmp[31] == 1)
            ladreg <= ladtmp + {19'd42280,11'b0};
        else
            ladreg <= ladtmp;
    end
end

// Add modulation bias according to the four-state sequence.
always @(posedge clk or negedge rst)
begin
    if(!rst)
        ladout <= 16'b0;
    else if(ladena2)
    begin
        if(state == 2'b11)
        begin
            if(tauCounter == 2)
                ladout <= ladreg[26:11] + 16'd`PIb;
            else
                ladout <= ladreg[26:11] + 16'd`PI;
        end
        else if(state == 2'b00)
        begin
            if(tauCounter == 2)
                ladout <= ladreg[26:11] + 16'd`PI;
            else
                ladout <= ladreg[26:11] + 16'd`PIb;
        end
        else if(state == 2'b01)
            ladout <= ladreg[26:11] + 16'd`PIbpPI;
        else if(state == 2'b10)
            ladout <= ladreg[26:11];
    end
end

endmodule

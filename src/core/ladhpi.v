// Phase-step waveform generator used by the first loop.
module ladhpi(
    rst,
    ladena1,
    ladena2,
    clk,
    ladin,
    state,
    cfg_sft_pd,
    cfg_PI,
    cfg_PIb,
    cfg_PIbpPI,
    ladout,
    tauCounter,
    updown,
    random
);
input rst;
input ladena1;
input ladena2;
input [31:0] ladin;
input clk;
input [1:0] state;
input [11:0] cfg_sft_pd;
input [15:0] cfg_PI;
input [15:0] cfg_PIb;
input [15:0] cfg_PIbpPI;
input random;
output [15:0] ladout;
output [11:0] tauCounter;
output updown;

reg [31:0] ladreg;
reg [15:0] ladout;
reg [31:0] ladtmp;
reg [11:0] tauCounter;
reg updown;

always @(posedge clk or negedge rst)
begin
    if (!rst)
        tauCounter <= 0;
    else if (ladena1)
    begin
        if (state == 2'b01 && tauCounter[0] != 1'b0)
            tauCounter[0] <= 1'b1;
        else if (state[0] == 1'b1)
        begin
            if (tauCounter >= cfg_sft_pd)
                tauCounter <= 1'b0;
            else
                tauCounter <= tauCounter + 1'b1;
        end
    end
end

always @(posedge clk or negedge rst)
begin
    if (!rst)
        updown <= 0;
    else if (tauCounter == cfg_sft_pd && ladena1 && state[0] == 1'b1)
        updown <= random;
end

always @(ladreg or ladin or updown or tauCounter or cfg_PIbpPI)
begin
    if (updown == 0 && tauCounter == 12'd1)
        ladtmp = ladreg + ladin + {cfg_PIbpPI, 11'b0};
    else if (updown == 1 && tauCounter == 12'd1)
        ladtmp = ladreg + ladin - {cfg_PIbpPI, 11'b0};
    else if (updown == 0 && tauCounter == 12'd2)
        ladtmp = ladreg + ladin + {cfg_PIbpPI, 11'b0};
    else if (updown == 1 && tauCounter == 12'd2)
        ladtmp = ladreg + ladin - {cfg_PIbpPI, 11'b0};
    else
        ladtmp = ladreg + ladin;
end

always @(posedge clk or negedge rst)
begin
    if (!rst)
        ladreg <= 32'b0;
    else if (ladena1 && state[0] == 1'b1)
    begin
        if (ladtmp[31] == 0 && ladtmp[31:11] >= 21'd253680)
            ladreg <= ladtmp - {19'd253680, 11'b0};
        else if (ladtmp[31] == 0 && ladtmp[31:11] >= 21'd211400)
            ladreg <= ladtmp - {19'd211400, 11'b0};
        else if (ladtmp[31] == 0 && ladtmp[31:11] >= 21'd169120)
            ladreg <= ladtmp - {19'd169120, 11'b0};
        else if (ladtmp[31] == 0 && ladtmp[31:11] >= 21'd126840)
            ladreg <= ladtmp - {19'd126840, 11'b0};
        else if (ladtmp[31] == 0 && ladtmp[31:11] >= 21'd84560)
            ladreg <= ladtmp - {19'd84560, 11'b0};
        else if (ladtmp[31] == 0 && ladtmp[31:11] >= 21'd42280)
            ladreg <= ladtmp - {19'd42280, 11'b0};
        else if (ladtmp[31] == 1 && ladtmp[31:11] < 21'h1CC638)
            ladreg <= ladtmp + {19'd253680, 11'b0};
        else if (ladtmp[31] == 1 && ladtmp[31:11] < 21'h1D6B60)
            ladreg <= ladtmp + {19'd211400, 11'b0};
        else if (ladtmp[31] == 1 && ladtmp[31:11] < 21'h1E1088)
            ladreg <= ladtmp + {19'd169120, 11'b0};
        else if (ladtmp[31] == 1 && ladtmp[31:11] < 21'h1EB5B0)
            ladreg <= ladtmp + {19'd126840, 11'b0};
        else if (ladtmp[31] == 1 && ladtmp[31:11] < 21'h1F5AD8)
            ladreg <= ladtmp + {19'd84560, 11'b0};
        else if (ladtmp[31] == 1)
            ladreg <= ladtmp + {19'd42280, 11'b0};
        else
            ladreg <= ladtmp;
    end
end

always @(posedge clk or negedge rst)
begin
    if (!rst)
        ladout <= 16'b0;
    else if (ladena2)
    begin
        if (state == 2'b11)
        begin
            if (tauCounter == 2)
                ladout <= ladreg[26:11] + cfg_PIb;
            else
                ladout <= ladreg[26:11] + cfg_PI;
        end
        else if (state == 2'b00)
        begin
            if (tauCounter == 2)
                ladout <= ladreg[26:11] + cfg_PI;
            else
                ladout <= ladreg[26:11] + cfg_PIb;
        end
        else if (state == 2'b01)
            ladout <= ladreg[26:11] + cfg_PIbpPI;
        else if (state == 2'b10)
            ladout <= ladreg[26:11];
    end
end

endmodule

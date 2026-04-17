// Angle pulse output with configurable pulse magnitude and width.
module angleoutputWithComp(rst,clk,intsout,counterN,N,pulse_k,pulse_width,sp,sn);
input rst;
input clk;
input [31:0] intsout;
input [9:0] counterN;
input [9:0] N;
input [31:0] pulse_k;
input [3:0] pulse_width;
output sp;
output sn;

wire [39:0] sum1;
wire [39:0] sum2;
wire [3:0] pulseWidthSafe;
wire [7:0] pulseWidthTwice;
wire [9:0] pulseWindowLimit;

reg sp;
reg sn;
reg [39:0] anglereg;
reg [7:0] smallCounter;

assign pulseWidthSafe = (pulse_width == 4'd0) ? 4'd1 : pulse_width;
assign pulseWidthTwice = {3'b000, pulseWidthSafe, 1'b0};
assign pulseWindowLimit = (N > 10'd4) ? (N - 10'd4) : 10'd0;
assign sum1 = anglereg + {8'd0, pulse_k};
assign sum2 = anglereg - {8'd0, pulse_k};

always @(posedge clk or negedge rst)
begin
    if (!rst)
        smallCounter <= 0;
    else if (counterN == 10'b1)
        smallCounter <= 0;
    else if (counterN >= 4 && counterN < pulseWindowLimit)
    begin
        if (smallCounter == pulseWidthTwice)
            smallCounter <= 8'b1;
        else
            smallCounter <= smallCounter + 8'b1;
    end
end

always @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        anglereg <= 0;
        sp <= 0;
        sn <= 0;
    end
    else
    begin
        if (counterN == 1)
        begin
            sn <= 0;
            sp <= 0;
            anglereg <= anglereg + {{8{intsout[31]}}, intsout};
        end
        else
        begin
            if (smallCounter == 1)
            begin
                if (anglereg[39] == 1 && sum1[39] == 1)
                begin
                    sn <= 1;
                    anglereg <= sum1;
                end
                else if (anglereg[39] == 0 && sum2[39] == 0)
                begin
                    sp <= 1;
                    anglereg <= sum2;
                end
            end
            else if (smallCounter == (8'd1 + {4'b0000, pulseWidthSafe}))
            begin
                sp <= 0;
                sn <= 0;
            end
        end
    end
end

endmodule

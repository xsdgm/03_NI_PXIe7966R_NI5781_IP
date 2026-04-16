/////////////////////////////////
//速率脉冲输出模块
/////////////////////////////////
`include "DEF.v"

module angleoutputWithComp(rst,clk,intsout,counterN,sp,sn);
input rst;
input clk;
input[31:0] intsout;
input[9:0] counterN;


output sp;
output sn;


//脉冲改窄为1/4
parameter K=1280000*2;			//控制脉冲对应的角度增量
parameter NpulseWidth=2;		//脉冲宽度
parameter NpulseMax=(`NTAU-4)/2/NpulseWidth;//一个渡越时间内的脉冲个数


wire[39:0] sum1;
wire[39:0] sum2;

reg sp;
reg sn;
reg[39:0] anglereg;
reg[3:0] smallCounter;


assign sum1=anglereg+K;
assign sum2=anglereg-K;



//通过小记数器循环计数来控制发脉冲的宽度
always@(posedge clk or negedge rst)	
begin
	if(!rst)
		smallCounter<=0;
	else if(counterN==10'b1)
		smallCounter<=0;
	else if(counterN>=4 && counterN<NpulseMax*NpulseWidth*2+4)
	begin
		if(smallCounter==2*NpulseWidth)
			smallCounter<=4'b1;
		else
			smallCounter<=smallCounter+4'b1;
	end
end

//发脉冲控制
always@(posedge clk or negedge rst)	
begin
    if(!rst)
    begin
       anglereg<=0;
       sp<=0;
       sn<=0;
    end
    else
	begin
       if(counterN==1)
       begin
          sn<=0;
          sp<=0;
						 
			  anglereg<=anglereg+{{8{intsout[31]}},intsout};// 加速率寄存器的数，速率寄存器的数扩展到40位
	   end
       else	//开始根据anglereg的结果往外发脉冲
	   begin
          if(smallCounter==1)	//脉宽为6个clk, 约180sec
          begin
             if(anglereg[39]==1 && sum1[39]==1)   //<0
             begin
                sn<=1;
                anglereg<=sum1;
             end
             else if(anglereg[39]==0 && sum2[39]==0) //>=0
             begin
                sp<=1;
                anglereg<=sum2;
             end
          end
          else if(smallCounter==1+NpulseWidth)
          begin
             sp<=0;
             sn<=0;
          end
	   end
	end
end


endmodule

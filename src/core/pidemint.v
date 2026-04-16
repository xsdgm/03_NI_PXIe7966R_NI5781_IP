//////////////////////////////
//第二闭环复位电压误差积分模块
//////////////////////////////

`include "DEF.v"


module pidemint(rst,ena,clk,counter,state,dVrefOut,VDARef,pintout,sdaSend,N);
input rst;
input ena;
input clk;
input[8:0] counter;
input[1:0] state;
input[31:0] dVrefOut;
input[13:0] VDARef;
input[9:0] N;
output[15:0] pintout;
output sdaSend;

reg[39:0] pintreg;
reg[15:0] pintoutpre;	//前一次的串行DA值 当新的值与之前的值不一样时，往串行DA重新写
reg sdaSend;

assign pintout=pintreg[39:24];

always@ (posedge clk)
begin
	if(!rst)
	begin
		pintreg<={VDARef,26'b0};
		pintoutpre<=16'b0;
		sdaSend<=1;	//初始写为1，这样开机rst就可以往串行DA中发一个数据
	end
	else if(ena)
	begin
		if(counter==N[9:1]-3 && state==2'b11)
		begin
			pintreg<=pintreg+{{8{dVrefOut[31]}},dVrefOut};	//dVrefOut;
		end
		else if(counter==N[9:1]-2 && state==2'b11 && pintoutpre!=pintreg[39:24])
		begin
			sdaSend<=1;
			pintoutpre<=pintreg[39:24];
		end
		else if(counter==12 && state==2'b00)	//(8+4)
		begin
			sdaSend<=0;
		end
	end
end


endmodule

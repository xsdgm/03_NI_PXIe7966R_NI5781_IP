///////////////////////////////
//Error demodulate 误差解调模块
///////////////////////////////

`include "DEF.v"

module demodulate(rst,ena,clk,adin,counter,state,dRotateOut,dVrefOut,counterN,N,tauCounter,updown,random);
input rst;
input ena;
input clk;
input[11:0] adin;	//12位AD输入
input[8:0] counter;
input[1:0] state;
output[31:0] dRotateOut;	//旋转误差解调输出
output[31:0] dVrefOut;		//参考电压解调输出

//--------------------------------------------
output random;		//AD最后一位作为随机因子
reg random;
reg randomPre;
//--------------------------------------------

reg[31:0] dRotateOut;
reg[31:0] dVrefOut;

///////////////////////
input[9:0] counterN;
input[9:0] N;
input[11:0] tauCounter;
input updown;
///////////////////////


///////////////////////
parameter delayAD=8;
parameter delay1=36-4;	//大尖延时
parameter delay2=22-4;	//小尖延时
parameter reserveN=7;
parameter delay=delayAD+delay1;	//N/2-delay-4
///////////////////////


//转动误差(1-3)-(2-4)
always@ (posedge clk or negedge rst)
begin
	if(!rst)
		dRotateOut<=32'b0;
	else if(ena)
	begin			
		if(counter==1 && state[0]==1'b0)	//@__@
			dRotateOut<=0;	
		else if(tauCounter==12'd2 || tauCounter==12'd3)	//在位移的两段时间内
				dRotateOut<=dRotateOut;					////////////////////
		else
		begin
			if(counterN>delayAD+delay1 && counterN<=N[9:1]+delayAD-1)
			begin
				if(state[1]==0)
					dRotateOut<=dRotateOut+adin;
				else if(state[1]==1)
					dRotateOut<=dRotateOut-adin;
			end
			else if(counter>delayAD+delay2 && counter<=N[9:1]-reserveN && state[0]==1)
			begin
				if(state[1]==0)
					dRotateOut<=dRotateOut-adin;
				else if(state[1]==1)
					dRotateOut<=dRotateOut+adin;
			end
		end
	end
end


//半波电压误差(1-2)+(3-4)
always@ (posedge clk or negedge rst)
begin
	if(!rst)
		dVrefOut<=32'b0;
	else if(ena)
	begin
		if(counter==1 && state==2'b00)
			dVrefOut<=0;
		else if(tauCounter==12'd2 || tauCounter==12'd3)
			dVrefOut<=dVrefOut;						////////////////////
		else
		begin
			if(counterN>delayAD+delay1 && counterN<=N[9:1]+delayAD-1)
				dVrefOut<=dVrefOut+adin;
			else if(counter>delayAD+delay2 && counter<=N[9:1]-reserveN && state[0]==1)
				dVrefOut<=dVrefOut-adin;

		end
	end
end



//产生随机数因子
always@ (posedge clk or negedge rst)
begin
	if(!rst)
	begin
		randomPre<=1'b0;
		random<=1'b0;
	end
	else if(ena)
	begin
		if(counter>delay && counter<=N[9:1]-4)
			randomPre<=randomPre+adin[0];
		else if(counter==N[9:1]-3 && state==2'b11 && tauCounter==12'd`SFT_PD)
		begin
			random<=randomPre;	//定期缓存并清0，再重新异或
		end
	end
end


endmodule

    
    


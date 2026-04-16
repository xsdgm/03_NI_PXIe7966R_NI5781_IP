////////////////////////
//串行DA输出模块
////////////////////////
//每2个节拍（一次误差解调周期），如果DA的寄存器数发生变化，则产生串行数据和串行DA时钟，更新Vref

module sdaout(rst,clk,counterN,N,sdaSend,pintout,sdaout,sdaclk,sdacs);
input rst;
input clk;
input[15:0] pintout;	
input[9:0] counterN;
input[9:0] N;	
input sdaSend;	 // sdaSend信号，该信号为高电平启动一次SPI通信
output sdaout;   // da1658 serial data out
output sdaclk;   // da1658 clock
output sdacs;    // da1658 cs

reg[15:0] sdaoutbuf;	//SPI移位寄存器
reg[3:0] shout_state;	//SPI移位状态
reg finish;				//finish==1表示SPI完成
reg sdacs;
reg sdaclk;

assign sdaout=sdaoutbuf[15];

//移位产生串行数据
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		sdaoutbuf<=0;
		sdacs<=1;
		shout_state<=0;
		finish<=1;
	end
	else
	begin
		if(counterN[2:0]==3'b000 && counterN>=8 && counterN<8*9)
		begin
			case(sdaSend)	//sdaSend为高电平时往串行DA发数
			1'b1:
			begin
				if(finish)	//上一次SPI完成
				begin
					sdaoutbuf<=pintout;	//装载16位数
					sdacs<=0;
					shout_state<=0;
					finish<=0;			//finish置1表示开始SPI
				end
				else
				begin
					sdaoutbuf<=sdaoutbuf<<1;
					shout_state<=shout_state+4'b1;
				end
			end
			1'b0:
			begin
				sdaoutbuf<=sdaoutbuf<<1;
				shout_state<=shout_state+4'b1;
			end
			endcase
		end
		else if(counterN==8*9 && shout_state==4'd15)	//状态完成
        begin
            shout_state<=0;
		    sdaoutbuf<=0;
			finish<=1;
        end
		else if(counterN==N && finish==1)				//发送完成，CS拉高，SDA更新
			sdacs<=1;
	end
end


//产生串行DA时钟
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		sdaclk<=0;
	end
	else if(sdacs==0)
	begin
		if(counterN[2:0]==3'b100 && counterN>=8 && counterN<=8*9)
			sdaclk<=1;
		else if(counterN[2:0]==3'b000 && counterN>=8 && counterN<=8*9)
			sdaclk<=0;
	end
end


endmodule

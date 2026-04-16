//------------------
//产生控制状态和时钟
//------------------
//要求N>="DEF.v"

`include "DEF.v"

module genclk(rst,ena,clk,N,counter,counterN,state,adclk,daclk,intena0,intena,ladena1,ladena2);
input rst;
input ena;
input clk;
input[9:0] N;
output[8:0] counter;	//1/2个节拍内的AD时钟计数
output[9:0] counterN;	//angleoutput和sdaout的控制状态
output[1:0] state;		//1~4节拍状态		
output adclk;
output daclk;
output intena0;			//乘反馈系数寄存使能信号
output intena;			//积分使能信号
output ladena1;			//阶梯波数值产生使能信号
output ladena2;

reg[8:0] counter;
reg[1:0] state;
reg[9:0] counterN;
reg daclk;
reg daclk1;
reg daclk2;
reg intena0;
reg intena;
reg ladena1;
reg ladena2;


assign adclk=clk;


//产生控制状态counter
always@ (posedge clk or negedge rst)
begin
    if(!rst)
    begin
       counter<=0;
       state<=2'b00;
    end
    else if(ena)
    begin   
       if(counter==N[9:1]+N[0] && state[0]==0)
       begin
          counter<=9'b1;
		  state<=state+1'b1;
       end
       else if(counter==N[9:1] && state[0]==1)
	   begin
          counter<=9'b1;
		  state<=state+1'b1;
	   end
	   else
		  counter<=counter+1'b1;
    end
end


//产生sdaout和angleoutput的控制计数器counterN
always@ (posedge clk or negedge rst)
begin
    if(!rst)
    begin
       counterN<=10'b0;
    end
    else if(ena)
    begin   
       if(counter==N[9:1] && state[0]==1)	//counterN与counter和state同步
          counterN<=10'b1;
       else
		  counterN<=counterN+1'b1;
    end
end


//daclk1(产生daclk1的代码不变)
always@ (posedge clk or negedge rst)
begin
    if(!rst)
    begin
       daclk1<=1'b0;
    end
    else if(ena)
    begin   
       if((counter==N[9:1]+N[0] && state[0]==0) || (counter==N[9:1] && state[0]==1) || counter==0)
          daclk1<=1'b1;
       else if(N[0]==1 && state[0]==1 && counter==63)
          daclk1<=1'b0;
	   else if(counter==64)
		  daclk1<=1'b0;
    end
end


//daclk2
always@ (negedge clk or negedge rst)
begin
    if(!rst)
    begin
       daclk2<=1'b0;
    end
    else if(ena)
    begin   
       if((counter==N[9:1]+N[0] && state[0]==0) || (counter==1 && state[0]==1) || counter==0)
          daclk2<=1'b1;
       else if(counter==64)
          daclk2<=1'b0;
    end
end


//产生DA时钟
always@ (daclk1 or daclk2 or N[0])
begin
	if(N[0]==1)
		daclk<=daclk1 | daclk2;
	else
		daclk<=daclk1;
end


//产生乘反馈系数寄存使能信号
always@ (posedge clk or negedge rst)
begin
    if(!rst)
    begin
       intena0<=1'b0;
    end
    else if(ena)
    begin   
       if(counter==N[9:1]-5 && state[0]==1'b1)	//@__@
          intena0<=1'b1;
       else if(counter==N[9:1]-4)
          intena0<=1'b0;
    end
end


//产生积分使能信号
always@ (posedge clk or negedge rst)
begin
    if(!rst)
    begin
       intena<=1'b0;
    end
    else if(ena)
    begin   
       if(counter==N[9:1]-4 && state[0]==1'b1)	//@__@
          intena<=1'b1;
       else if(counter==N[9:1]-3)
          intena<=1'b0;
    end
end


//产生阶梯波数据产生使能信号ladena1
always@ (posedge clk or negedge rst)
begin
    if(!rst)
    begin
       ladena1<=1'b0;
    end
    else if(ena)
    begin   
       if(counter==N[9:1]-3)
          ladena1<=1'b1;
       else if(counter==N[9:1]-2)
          ladena1<=1'b0;
    end
end


//产生阶梯波数据产生使能信号ladena2
always@ (posedge clk or negedge rst)
begin
    if(!rst)
    begin
       ladena2<=1'b0;
    end
    else if(ena)
    begin   
       if(counter==N[9:1]-2)
          ladena2<=1'b1;
       else if(counter==N[9:1]-1)
          ladena2<=1'b0;
    end
end


endmodule

////////////////////////////////////////////////////
////////////////////////////////////////////////////


///////////////////////
//速率误差积分模块
///////////////////////

module integrator(rst,intena,clk,dRotateOut,intsout);
input rst;   //asynchronous clear
input intena;   //latch enable
input clk;
input[31:0] dRotateOut;   //32 bit data in
output[31:0] intsout;   //32 bit data out

reg[31:0] intsout;
wire[31:0] sum;


//************************
assign sum=intsout+dRotateOut;	//dRotateOut;//{dRotateOut[30:0],1'b0};	//{dRotateOut[31],dRotateOut[31:1]};//{dRotateOut[30:0],1'b0};
//************************


//误差积分
always@ (posedge clk or negedge rst)
begin
    if(!rst)
		intsout<=0;
    else if(intena)
	begin
		if(sum[31]==0 && sum[31:11]>=21'd249452)	    //限<+11.8pi 249452
			intsout<=sum-{19'd253680,11'b0};			//超过11.8PI，-12PI
		else if(sum[31]==1 && sum[31:11]<21'h1C3194)	//限>-11.8pi -249452
			intsout<=sum+{19'd253680,11'b0};			//小于-11.8PI，+12PI
		else
			intsout<=sum;
	end
end


endmodule

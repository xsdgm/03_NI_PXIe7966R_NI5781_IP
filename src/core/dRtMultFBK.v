//解调量乘以反馈系数 *K/2^5 精度1/32
module dRtMultFBK(rst,intena0,clk,FBK,dRotateOut24,dRotateOutFBK);
input rst;
input intena0;
input clk;
input[7:0] FBK;				//反馈系数0~255
input[23:0] dRotateOut24;	//取解调量的后24位数计算
output[31:0] dRotateOutFBK;

wire[32:0] mult_FBK;		//解调量乘以系数33bit
reg[32:0] mult_FBK_R;		//解调量乘以系数加余数


assign mult_FBK=$signed(dRotateOut24[23:0])*$signed({1'b0,FBK});


always@(posedge clk or negedge rst)
begin
	if(!rst)
		mult_FBK_R<=33'b0;
	else if(intena0==1)	//intena0在intena之前一个clk
		mult_FBK_R<=mult_FBK+mult_FBK_R[4:0];
end


assign dRotateOutFBK={{4{mult_FBK_R[32]}},mult_FBK_R[32:5]};


endmodule

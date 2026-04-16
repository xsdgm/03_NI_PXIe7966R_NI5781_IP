//异步复位，同步释放模块
//该模块被引用3次
module asReset(clk,rst_n,rst_nr2);
input clk;
input rst_n;
output rst_nr2;

reg rst_nr1;
reg rst_nr2;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		rst_nr1<=1'b0;
	else
		rst_nr1<=1'b1;
end

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		rst_nr2<=1'b0;
	else
		rst_nr2<=rst_nr1;
end

endmodule


`include "DEF.v"

// NI PXIe-7966R / LabVIEW FPGA friendly wrapper.
// This wrapper keeps the original four-state square-wave modulation algorithm,
// but removes the Cyclone-specific PLL, pin constraints, and MCU SPI config path.
module fog_core_ni7966r #(
    parameter [9:0]  DEFAULT_N       = 10'd170,
    parameter [13:0] DEFAULT_VDAREF  = 14'd13280,
    parameter [7:0]  DEFAULT_FBK     = 8'd100,
    parameter [7:0]  DEFAULT_FBK2    = 8'd32
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cfg_apply,
    input  wire [9:0]  cfg_N,
    input  wire [13:0] cfg_VDARef,
    input  wire [7:0]  cfg_FBK,
    input  wire [7:0]  cfg_FBK2,
    input  wire [11:0] adin,
    output wire        ready,
    output wire        adclk,
    output wire        daclk,
    output wire [15:0] daout,
    output wire [15:0] vref_word,
    output wire        sdaout,
    output wire        sdaclk,
    output wire        sdacs,
    output wire        sp,
    output wire        sn,
    output wire [1:0]  state_dbg,
    output wire [8:0]  counter_dbg,
    output wire [9:0]  counterN_dbg,
    output wire [11:0] tau_dbg,
    output wire [31:0] intsout_dbg,
    output wire [31:0] drotate_dbg,
    output wire [31:0] dvref_dbg
);

wire ena;
wire sys_rst;
wire intena0;
wire intena;
wire ladena1;
wire ladena2;
wire [9:0] N;
wire [8:0] counter;
wire [9:0] counterN;
wire [1:0] state;
wire [13:0] VDARef;
wire [7:0] FBK;
wire [7:0] FBK2;
wire [31:0] dRotateOut;
wire [31:0] dVrefOut;
wire [31:0] dRotateOutFBK;
wire [31:0] dVrefOutFBK;
wire [31:0] intsout;
wire [15:0] pintout;
wire sdaSend;
wire [11:0] tauCounter;
wire updown;
wire random;

reg [9:0]  cfg_n_reg;
reg [13:0] cfg_vdaref_reg;
reg [7:0]  cfg_fbk_reg;
reg [7:0]  cfg_fbk2_reg;
reg [1:0]  cfg_reset_hold;

localparam [11:0] CFG_SFT_PD_DEFAULT = `SFT_PD;
localparam [15:0] CFG_PI_DEFAULT     = 16'd21140;
localparam [15:0] CFG_PIB_DEFAULT    = 16'd23254;
localparam [15:0] CFG_PIBPPI_DEFAULT = 16'd2114;

assign ena         = 1'b1;
assign N           = cfg_n_reg;
assign VDARef      = cfg_vdaref_reg;
assign FBK         = cfg_fbk_reg;
assign FBK2        = cfg_fbk2_reg;
assign vref_word   = pintout;
assign ready       = sys_rst;
assign state_dbg   = state;
assign counter_dbg = counter;
assign counterN_dbg = counterN;
assign tau_dbg     = tauCounter;
assign intsout_dbg = intsout;
assign drotate_dbg = dRotateOut;
assign dvref_dbg   = dVrefOut;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cfg_n_reg      <= DEFAULT_N;
        cfg_vdaref_reg <= DEFAULT_VDAREF;
        cfg_fbk_reg    <= DEFAULT_FBK;
        cfg_fbk2_reg   <= DEFAULT_FBK2;
        cfg_reset_hold <= 2'b00;
    end else begin
        if (cfg_apply) begin
            cfg_n_reg      <= cfg_N;
            cfg_vdaref_reg <= cfg_VDARef;
            cfg_fbk_reg    <= cfg_FBK;
            cfg_fbk2_reg   <= cfg_FBK2;
            cfg_reset_hold <= 2'b00;
        end else if (cfg_reset_hold != 2'b11) begin
            cfg_reset_hold <= cfg_reset_hold + 1'b1;
        end
    end
end

// Keep the original reset style: asynchronous assert, synchronous release.
asReset asrst_core(
    .clk(clk),
    .rst_n(rst_n & cfg_reset_hold[1]),
    .rst_nr2(sys_rst)
);

genclk gclk(
    .rst(sys_rst),
    .ena(ena),
    .clk(clk),
    .N(N),
    .counter(counter),
    .counterN(counterN),
    .state(state),
    .adclk(adclk),
    .daclk(daclk),
    .intena0(intena0),
    .intena(intena),
    .ladena1(ladena1),
    .ladena2(ladena2)
);

demodulate dmt(
    .rst(sys_rst),
    .ena(ena),
    .clk(clk),
    .adin(adin),
    .counter(counter),
    .state(state),
    .dRotateOut(dRotateOut),
    .dVrefOut(dVrefOut),
    .counterN(counterN),
    .N(N),
    .tauCounter(tauCounter),
    .updown(updown),
    .random(random)
);

dRtMultFBK dmk(
    .rst(sys_rst),
    .intena0(intena0),
    .clk(clk),
    .FBK(FBK),
    .dRotateOut24(dRotateOut[23:0]),
    .dRotateOutFBK(dRotateOutFBK)
);

dRtMultFBK dmk_vref(
    .rst(sys_rst),
    .intena0(intena0),
    .clk(clk),
    .FBK(FBK2),
    .dRotateOut24(dVrefOut[23:0]),
    .dRotateOutFBK(dVrefOutFBK)
);

integrator itg(
    .rst(sys_rst),
    .intena(intena),
    .clk(clk),
    .dRotateOut({dRotateOutFBK[28:0], 3'b0}),
    .intsout(intsout)
);

ladhpi ldp(
    .rst(sys_rst),
    .ladena1(ladena1),
    .ladena2(ladena2),
    .clk(clk),
    .ladin(intsout),
    .state(state),
    .cfg_sft_pd(CFG_SFT_PD_DEFAULT),
    .cfg_PI(CFG_PI_DEFAULT),
    .cfg_PIb(CFG_PIB_DEFAULT),
    .cfg_PIbpPI(CFG_PIBPPI_DEFAULT),
    .ladout(daout),
    .tauCounter(tauCounter),
    .updown(updown),
    .random(random)
);

pidemint pint(
    .rst(sys_rst),
    .ena(ena),
    .clk(clk),
    .counter(counter),
    .state(state),
    .dVrefOut({dVrefOutFBK[28:0], 3'b0}),
    .VDARef(VDARef),
    .pintout(pintout),
    .sdaSend(sdaSend),
    .N(N)
);

sdaout sdo(
    .rst(sys_rst),
    .clk(clk),
    .counterN(counterN),
    .N(N),
    .sdaSend(sdaSend),
    .pintout(pintout),
    .sdaout(sdaout),
    .sdaclk(sdaclk),
    .sdacs(sdacs)
);

angleoutputWithComp agowc(
    .rst(sys_rst),
    .clk(clk),
    .intsout(intsout),
    .counterN(counterN),
    .sp(sp),
    .sn(sn)
);

endmodule

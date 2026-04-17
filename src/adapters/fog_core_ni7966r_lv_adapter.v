// LabVIEW FPGA adapter wrapper matching the "AI -> IP -> AO" wiring style.
// Assumption:
// - ai0_raw carries the demodulation ADC sample used by the FOG algorithm.
// - ao0_raw outputs the main modulation DAC code.
// - ao1_raw outputs the Vref compensation DAC code.
// - ai1_raw is currently reserved for future use.
module fog_core_ni7966r_lv_adapter #(
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
    input  wire [15:0] ai0_raw,
    input  wire [15:0] ai1_raw,
    output wire [15:0] ao0_raw,
    output wire [15:0] ao1_raw,
    output wire        dio_sp,
    output wire        dio_sn,
    output wire        status_ready,
    output wire [1:0]  state_dbg
);

wire unused_ai1;
wire adclk_unused;
wire daclk_unused;
wire sdaout_unused;
wire sdaclk_unused;
wire sdacs_unused;
wire [8:0] counter_dbg_unused;
wire [9:0] counterN_dbg_unused;
wire [11:0] tau_dbg_unused;
wire [31:0] intsout_dbg_unused;
wire [31:0] drotate_dbg_unused;
wire [31:0] dvref_dbg_unused;

assign unused_ai1 = ^ai1_raw;

fog_core_ni7966r #(
    .DEFAULT_N(DEFAULT_N),
    .DEFAULT_VDAREF(DEFAULT_VDAREF),
    .DEFAULT_FBK(DEFAULT_FBK),
    .DEFAULT_FBK2(DEFAULT_FBK2)
) u_core (
    .clk(clk),
    .rst_n(rst_n),
    .cfg_apply(cfg_apply),
    .cfg_N(cfg_N),
    .cfg_VDARef(cfg_VDARef),
    .cfg_FBK(cfg_FBK),
    .cfg_FBK2(cfg_FBK2),
    .adin(ai0_raw[11:0]),
    .ready(status_ready),
    .adclk(adclk_unused),
    .daclk(daclk_unused),
    .daout(ao0_raw),
    .vref_word(ao1_raw),
    .sdaout(sdaout_unused),
    .sdaclk(sdaclk_unused),
    .sdacs(sdacs_unused),
    .sp(dio_sp),
    .sn(dio_sn),
    .state_dbg(state_dbg),
    .counter_dbg(counter_dbg_unused),
    .counterN_dbg(counterN_dbg_unused),
    .tau_dbg(tau_dbg_unused),
    .intsout_dbg(intsout_dbg_unused),
    .drotate_dbg(drotate_dbg_unused),
    .dvref_dbg(dvref_dbg_unused)
);

endmodule

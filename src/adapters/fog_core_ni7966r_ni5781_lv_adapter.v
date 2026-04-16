// Recommended LabVIEW FPGA adapter for PXIe-7966R + NI 5781.
//
// This wrapper follows the current "AI -> IP -> AO" wiring style:
// - AI0 feeds the demodulation sample path
// - AO0 outputs the main modulation word
// - AO1 outputs the second-loop Vref compensation word
// - SP/SN remain available as digital pulse outputs
module fog_core_ni7966r_ni5781_lv_adapter #(
    parameter [9:0]  DEFAULT_N       = 10'd170,
    parameter [13:0] DEFAULT_VDAREF  = 14'd13280,
    parameter [7:0]  DEFAULT_FBK     = 8'd100
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cfg_apply,
    input  wire [9:0]  cfg_N,
    input  wire [13:0] cfg_VDARef,
    input  wire [7:0]  cfg_FBK,
    input  wire [1:0]  ai_map_mode,
    input  wire [15:0] ai0_raw,
    input  wire [15:0] ai1_raw,
    output wire [15:0] ao0_raw,
    output wire [15:0] ao1_raw,
    output wire        dio_sp,
    output wire        dio_sn,
    output wire        status_ready,
    output wire [1:0]  state_dbg,
    output wire [11:0] adin_dbg
);

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
wire unused_ai1;
wire [11:0] adin_mapped;

assign unused_ai1 = ^ai1_raw;
assign adin_dbg   = adin_mapped;

ni5781_ai_to_adin12 u_ai_map (
    .ai_raw(ai0_raw),
    .map_mode(ai_map_mode),
    .adin(adin_mapped)
);

fog_core_ni7966r #(
    .DEFAULT_N(DEFAULT_N),
    .DEFAULT_VDAREF(DEFAULT_VDAREF),
    .DEFAULT_FBK(DEFAULT_FBK)
) u_core (
    .clk(clk),
    .rst_n(rst_n),
    .cfg_apply(cfg_apply),
    .cfg_N(cfg_N),
    .cfg_VDARef(cfg_VDARef),
    .cfg_FBK(cfg_FBK),
    .adin(adin_mapped),
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

// Recommended LabVIEW FPGA adapter for PXIe-7966R + NI 5781.
//
// This wrapper follows the current "AI -> IP -> AO" wiring style:
// - AI0 feeds the demodulation sample path
// - AO0 outputs the V2Pi-scaled phase-step waveform for the modulator
// - AO1 exposes the raw ladhpi/daout phase-step word for observation
// - cfg_V2Pai_mV is the half-wave voltage in millivolts, e.g. 1800 for 1.8 V
// - cfg_N is accepted up to 1022 in LabVIEW mode; zero falls back to the
//   default timing, and other values outside 68..1022 are clamped, then
//   forced even, before entering the timing core
// - sp_sn_value exposes the gyro pulse difference directly
module fog_core_ni7966r_ni5781_lv_adapter #(
    parameter [9:0]  DEFAULT_N       = 10'd680,
    parameter [15:0] DEFAULT_V2PAI_MV = 16'd1800,
    parameter [7:0]  DEFAULT_FBK     = 8'd100,
    parameter [7:0]  DEFAULT_FBK2    = 8'd32
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        cfg_apply,
    input  wire [9:0]  cfg_N,
    input  wire [15:0] cfg_V2Pai_mV,
    input  wire [7:0]  cfg_FBK,
    input  wire [7:0]  cfg_FBK2,
    input  wire [1:0]  ai_map_mode,
    input  wire [15:0] ai0_raw,
    output wire [15:0] ao0_raw,
    output wire [15:0] ao1_raw,
    output wire signed [15:0] sp_sn_value,
    output wire        status_ready,
    output wire [1:0]  state_dbg,
    output wire [11:0] adin_dbg
);

wire adclk_unused;
wire daclk_unused;
wire sdaout_unused;
wire sdaclk_unused;
wire sdacs_unused;
wire sp_unused;
wire sn_unused;
wire [8:0] counter_dbg_unused;
wire [9:0] counterN_dbg_unused;
wire [11:0] tau_dbg_unused;
wire [31:0] intsout_dbg_unused;
wire [31:0] drotate_dbg_unused;
wire [31:0] dvref_dbg_unused;
wire [11:0] adin_mapped;
wire [15:0] daout_unscaled;
wire [15:0] vref_word;
wire [15:0] cfg_v2pai_limited;
wire [31:0] cfg_vdaref_scaled;
wire [13:0] cfg_vdaref_code;
wire [9:0] cfg_n_clamped;
wire [9:0] cfg_n_safe;
reg        scale_busy;
reg [5:0]  scale_phase;
reg [15:0] scale_mod_latch;
reg [15:0] scale_vref_latch;
reg [31:0] scale_product1;
reg [48:0] scale_product2;
reg [15:0] scale_last_mod;
reg [15:0] scale_last_vref;
reg        scale_last_valid;
reg [15:0] ao0_raw_r;

localparam [9:0] DEFAULT_N_SAFE =
    ((DEFAULT_N < 10'd68) ? 10'd68 :
     (DEFAULT_N > 10'd1022) ? 10'd1022 : DEFAULT_N) & 10'h3fe;
localparam [15:0] DEFAULT_V2PAI_LIMITED =
    (DEFAULT_V2PAI_MV > 16'd2500) ? 16'd2500 : DEFAULT_V2PAI_MV;
localparam [31:0] DEFAULT_VDAREF_SCALED =
    (DEFAULT_V2PAI_LIMITED * 32'd26842) + 32'd2048;
localparam [31:0] DEFAULT_VDAREF_SHIFTED = DEFAULT_VDAREF_SCALED >> 12;
localparam [13:0] DEFAULT_VDAREF_CODE =
    (DEFAULT_VDAREF_SHIFTED > 32'd16383) ? 14'h3fff : DEFAULT_VDAREF_SHIFTED;
localparam [15:0] DEFAULT_VREF_WORD = {DEFAULT_VDAREF_CODE, 2'b00};
localparam [15:0] VREF_RECIP_Q31 =
    (((49'd1 << 31) + (DEFAULT_VREF_WORD >> 1)) / DEFAULT_VREF_WORD);

assign adin_dbg   = adin_mapped;
assign cfg_n_clamped = (cfg_N == 10'd0) ? DEFAULT_N_SAFE :
                       (cfg_N < 10'd68) ? 10'd68 :
                       (cfg_N > 10'd1022) ? 10'd1022 : cfg_N;
assign cfg_n_safe = {cfg_n_clamped[9:1], 1'b0};
assign cfg_v2pai_limited = (cfg_V2Pai_mV > 16'd2500) ? 16'd2500 : cfg_V2Pai_mV;
assign cfg_vdaref_scaled = (cfg_v2pai_limited * 32'd26842) + 32'd2048;
assign cfg_vdaref_code = (cfg_vdaref_scaled[31:12] > 20'd16383) ? 14'h3fff : cfg_vdaref_scaled[25:12];
assign ao0_raw = ao0_raw_r;
assign ao1_raw = daout_unscaled;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scale_busy <= 1'b0;
        scale_phase <= 6'd0;
        scale_mod_latch <= 16'd0;
        scale_vref_latch <= 16'd0;
        scale_product1 <= 32'd0;
        scale_product2 <= 49'd0;
        scale_last_mod <= 16'd0;
        scale_last_vref <= 16'd0;
        scale_last_valid <= 1'b0;
        ao0_raw_r <= 16'd0;
    end else begin
        if (!scale_busy &&
            (!scale_last_valid ||
             daout_unscaled != scale_last_mod ||
             vref_word != scale_last_vref)) begin
            scale_busy <= 1'b1;
            scale_phase <= 6'd0;
            scale_mod_latch <= daout_unscaled;
            scale_vref_latch <= vref_word;
            scale_product1 <= 32'd0;
            scale_product2 <= 49'd0;
            scale_last_mod <= daout_unscaled;
            scale_last_vref <= vref_word;
            scale_last_valid <= 1'b1;
        end else if (scale_phase < 6'd16) begin
            if (scale_vref_latch[scale_phase[3:0]])
                scale_product1 <= scale_product1 + ({{16{1'b0}}, scale_mod_latch} << scale_phase[3:0]);
            scale_phase <= scale_phase + 1'b1;
        end else if (scale_phase < 6'd32) begin
            if (scale_phase == 6'd16)
                scale_product2 <= 49'd1073741824;
            if (VREF_RECIP_Q31[scale_phase[3:0]]) begin
                if (scale_phase == 6'd16)
                    scale_product2 <= 49'd1073741824 + {17'd0, scale_product1};
                else
                    scale_product2 <= scale_product2 + ({17'd0, scale_product1} << scale_phase[3:0]);
            end
            scale_phase <= scale_phase + 1'b1;
        end else begin
            ao0_raw_r <= (scale_product2[48] || scale_product2[47]) ?
                         16'hffff : scale_product2[46:31];
            scale_busy <= 1'b0;
        end
    end
end

ni5781_ai_to_adin12 u_ai_map (
    .ai_raw(ai0_raw),
    .map_mode(ai_map_mode),
    .adin(adin_mapped)
);

fog_core_ni7966r #(
    .DEFAULT_N(DEFAULT_N_SAFE),
    .DEFAULT_VDAREF(DEFAULT_VDAREF_CODE),
    .DEFAULT_FBK(DEFAULT_FBK),
    .DEFAULT_FBK2(DEFAULT_FBK2)
) u_core (
    .clk(clk),
    .rst_n(rst_n),
    .cfg_apply(cfg_apply),
    .cfg_N(cfg_n_safe),
    .cfg_VDARef(cfg_vdaref_code),
    .cfg_FBK(cfg_FBK),
    .cfg_FBK2(cfg_FBK2),
    .adin(adin_mapped),
    .ready(status_ready),
    .adclk(adclk_unused),
    .daclk(daclk_unused),
    .daout(daout_unscaled),
    .vref_word(vref_word),
    .sdaout(sdaout_unused),
    .sdaclk(sdaclk_unused),
    .sdacs(sdacs_unused),
    .sp(sp_unused),
    .sn(sn_unused),
    .sp_sn_value(sp_sn_value),
    .state_dbg(state_dbg),
    .counter_dbg(counter_dbg_unused),
    .counterN_dbg(counterN_dbg_unused),
    .tau_dbg(tau_dbg_unused),
    .intsout_dbg(intsout_dbg_unused),
    .drotate_dbg(drotate_dbg_unused),
    .dvref_dbg(dvref_dbg_unused)
);

endmodule


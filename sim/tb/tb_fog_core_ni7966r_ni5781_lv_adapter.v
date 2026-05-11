`timescale 1ns/1ps

module tb_fog_core_ni7966r_ni5781_lv_adapter;

reg         clk;
reg         rst_n;
reg         cfg_apply;
reg  [9:0]  cfg_N;
reg  [15:0] cfg_V2Pai_mV;
reg  [7:0]  cfg_FBK;
reg  [7:0]  cfg_FBK2;
reg  [1:0]  ai_map_mode;
reg  [15:0] ai0_raw;

wire [15:0] ao0_raw;
wire signed [15:0] sp_sn_value;
wire        status_ready;
wire [1:0]  state_dbg;
wire [11:0] adin_dbg;

integer errors;
integer cycles_after_ready;
integer state_seen_mask;
integer ao0_change_count;
reg [15:0] ao0_prev;

fog_core_ni7966r_ni5781_lv_adapter dut (
    .clk(clk),
    .rst_n(rst_n),
    .cfg_apply(cfg_apply),
    .cfg_N(cfg_N),
    .cfg_V2Pai_mV(cfg_V2Pai_mV),
    .cfg_FBK(cfg_FBK),
    .cfg_FBK2(cfg_FBK2),
    .ai_map_mode(ai_map_mode),
    .ai0_raw(ai0_raw),
    .ao0_raw(ao0_raw),
    .sp_sn_value(sp_sn_value),
    .status_ready(status_ready),
    .state_dbg(state_dbg),
    .adin_dbg(adin_dbg)
);

always #12.5 clk = ~clk;

always @(posedge clk) begin
    if (!rst_n) begin
        ai0_raw <= 16'd0;
    end else begin
        // Signed ramp to exercise the NI 5781 AI mapping path.
        ai0_raw <= ai0_raw + 16'sd64;
    end
end

always @(posedge clk) begin
    if (!status_ready) begin
        cycles_after_ready <= 0;
        state_seen_mask <= 0;
        ao0_change_count <= 0;
        ao0_prev <= 16'h0000;
    end else begin
        cycles_after_ready <= cycles_after_ready + 1;
        state_seen_mask[state_dbg] <= 1'b1;

        if (^ao0_raw === 1'bx) begin
            $display("TB FAIL top: ao0_raw has X at t=%0t", $time);
            errors <= errors + 1;
        end

        if (^adin_dbg === 1'bx) begin
            $display("TB FAIL top: adin_dbg has X at t=%0t", $time);
            errors <= errors + 1;
        end

        if (^sp_sn_value === 1'bx) begin
            $display("TB FAIL top: sp_sn_value has X at t=%0t", $time);
            errors <= errors + 1;
        end

        if (sp_sn_value !== -16'sd1 && sp_sn_value !== 16'sd0 && sp_sn_value !== 16'sd1) begin
            $display("TB FAIL top: sp_sn_value out of range value=%0d at t=%0t",
                     sp_sn_value, $time);
            errors <= errors + 1;
        end

        if (ao0_raw !== ao0_prev) begin
            ao0_change_count <= ao0_change_count + 1;
            ao0_prev <= ao0_raw;
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cfg_apply = 1'b0;
    cfg_N = 10'd170;
    cfg_V2Pai_mV = 16'd1800;
    cfg_FBK = 8'd100;
    cfg_FBK2 = 8'd32;
    ai_map_mode = 2'b01;
    ai0_raw = 16'd0;
    errors = 0;
    cycles_after_ready = 0;
    state_seen_mask = 0;
    ao0_change_count = 0;
    ao0_prev = 16'h0000;

    $dumpfile("sim/icarus/tb_fog_core_ni7966r_ni5781_lv_adapter.vcd");
    $dumpvars(0, tb_fog_core_ni7966r_ni5781_lv_adapter);

    #100;
    rst_n = 1'b1;

    repeat (8) @(posedge clk);
    cfg_N = 10'd1023;
    cfg_apply = 1'b1;
    @(posedge clk);
    cfg_apply = 1'b0;

    repeat (2500) @(posedge clk);

    if (status_ready !== 1'b1) begin
        $display("TB FAIL top: status_ready never asserted");
        errors = errors + 1;
    end

    if ((state_seen_mask & 4'b1111) != 4'b1111) begin
        $display("TB FAIL top: four-state sequence incomplete mask=%0d", state_seen_mask);
        errors = errors + 1;
    end

    if (ao0_change_count < 4) begin
        $display("TB FAIL top: ao0_raw changed too few times count=%0d", ao0_change_count);
        errors = errors + 1;
    end

    if (errors == 0) begin
        $display("TB PASS top: ready=%0d state_mask=0x%0h ao0_changes=%0d adin_dbg=%0d ao0=0x%04h",
                 status_ready, state_seen_mask, ao0_change_count, adin_dbg, ao0_raw);
    end else begin
        $display("TB FAIL top total_errors=%0d", errors);
    end

    $finish;
end

endmodule

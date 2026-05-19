`timescale 1ns/1ps

module tb_lv_adapter_config_sweep;

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
wire [15:0] ao1_raw;
wire signed [15:0] sp_sn_value;
wire        status_ready;
wire [1:0]  state_dbg;
wire [11:0] adin_dbg;

integer errors;
integer cycle;
integer changes;
integer state_mask;
integer min_ao;
integer max_ao;
integer raw_changes;
integer ao_gap;
integer min_ao_gap;
integer expected_half_cycles;
reg [15:0] prev_ao;
reg [15:0] prev_raw_ao;

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
    .ao1_raw(ao1_raw),
    .sp_sn_value(sp_sn_value),
    .status_ready(status_ready),
    .state_dbg(state_dbg),
    .adin_dbg(adin_dbg)
);

always #12.5 clk = ~clk;

function [13:0] expected_vref_code;
    input [15:0] mv;
    reg [31:0] raw;
    reg [15:0] limited_mv;
    begin
        limited_mv = (mv > 16'd2500) ? 16'd2500 : mv;
        raw = (limited_mv * 32'd26842) + 32'd2048;
        expected_vref_code = (raw[31:12] > 20'd16383) ? 14'h3fff : raw[25:12];
    end
endfunction

function [9:0] expected_n_safe;
    input [9:0] n_in;
    begin
        if (n_in == 10'd0)
            expected_n_safe = 10'd680;
        else if (n_in < 10'd68)
            expected_n_safe = 10'd68;
        else if (n_in > 10'd1022)
            expected_n_safe = 10'd1022;
        else
            expected_n_safe = {n_in[9:1], 1'b0};
    end
endfunction

task run_case;
    input [9:0] n_in;
    input [15:0] v2pai_mv_in;
    input [127:0] label;
    integer run_cycles;
    reg [9:0] n_expect;
    reg [13:0] vref_expect;
    begin
        n_expect = expected_n_safe(n_in);
        vref_expect = expected_vref_code(v2pai_mv_in);
        run_cycles = (n_expect * 5) + 200;

        rst_n = 1'b0;
        cfg_apply = 1'b0;
        cfg_N = n_in;
        cfg_V2Pai_mV = v2pai_mv_in;
        ai0_raw = 16'h2000;
        repeat (6) @(posedge clk);
        rst_n = 1'b1;
        repeat (6) @(posedge clk);
        cfg_apply = 1'b1;
        @(posedge clk);
        cfg_apply = 1'b0;

        changes = 0;
        state_mask = 0;
        min_ao = 65535;
        max_ao = 0;
        raw_changes = 0;
        ao_gap = 0;
        min_ao_gap = 32'h7fffffff;
        expected_half_cycles = n_expect / 2;
        prev_ao = ao0_raw;
        prev_raw_ao = ao1_raw;

        for (cycle = 0; cycle < run_cycles; cycle = cycle + 1) begin
            @(posedge clk);
            state_mask[state_dbg] = 1'b1;

            if (^ao0_raw === 1'bx) begin
                $display("TB FAIL sweep %0s: ao0_raw has X at cycle=%0d", label, cycle);
                errors = errors + 1;
            end

            if (^ao1_raw === 1'bx) begin
                $display("TB FAIL sweep %0s: ao1_raw has X at cycle=%0d", label, cycle);
                errors = errors + 1;
            end

            if (ao1_raw !== dut.daout_unscaled) begin
                $display("TB FAIL sweep %0s: ao1_raw=0x%04h expected raw daout=0x%04h",
                         label, ao1_raw, dut.daout_unscaled);
                errors = errors + 1;
            end

            if (^sp_sn_value === 1'bx) begin
                $display("TB FAIL sweep %0s: sp_sn_value has X at cycle=%0d", label, cycle);
                errors = errors + 1;
            end

            if (sp_sn_value !== -16'sd1 && sp_sn_value !== 16'sd0 && sp_sn_value !== 16'sd1) begin
                $display("TB FAIL sweep %0s: sp_sn_value out of range value=%0d", label, sp_sn_value);
                errors = errors + 1;
            end

            if (ao0_raw !== prev_ao) begin
                if (changes != 0 && ao_gap < min_ao_gap)
                    min_ao_gap = ao_gap;
                ao_gap = 0;
                changes = changes + 1;
                prev_ao = ao0_raw;
            end else begin
                ao_gap = ao_gap + 1;
            end

            if (ao1_raw !== prev_raw_ao) begin
                raw_changes = raw_changes + 1;
                prev_raw_ao = ao1_raw;
            end

            if (ao0_raw < min_ao)
                min_ao = ao0_raw;
            if (ao0_raw > max_ao)
                max_ao = ao0_raw;
        end

        if (status_ready !== 1'b1) begin
            $display("TB FAIL sweep %0s: status_ready not asserted", label);
            errors = errors + 1;
        end

        if (dut.cfg_n_safe !== n_expect) begin
            $display("TB FAIL sweep %0s: cfg_n_safe=%0d expected=%0d", label, dut.cfg_n_safe, n_expect);
            errors = errors + 1;
        end

        if (dut.cfg_vdaref_code !== vref_expect) begin
            $display("TB FAIL sweep %0s: cfg_vdaref_code=%0d expected=%0d",
                     label, dut.cfg_vdaref_code, vref_expect);
            errors = errors + 1;
        end

        if ((state_mask & 4'b1111) != 4'b1111) begin
            $display("TB FAIL sweep %0s: state sequence incomplete mask=0x%0h", label, state_mask);
            errors = errors + 1;
        end

        if (changes < 4) begin
            $display("TB FAIL sweep %0s: ao0_raw changed too few times changes=%0d", label, changes);
            errors = errors + 1;
        end

        if (raw_changes < 4) begin
            $display("TB FAIL sweep %0s: ao1_raw changed too few times changes=%0d", label, raw_changes);
            errors = errors + 1;
        end

        if (v2pai_mv_in != 16'd0 && max_ao <= min_ao) begin
            $display("TB FAIL sweep %0s: ao0 range invalid min=%0d max=%0d", label, min_ao, max_ao);
            errors = errors + 1;
        end

        if (changes > 1 && min_ao_gap < (expected_half_cycles - 2)) begin
            $display("TB FAIL sweep %0s: ao0 update too fast min_gap=%0d expected_half=%0d",
                     label, min_ao_gap, expected_half_cycles);
            errors = errors + 1;
        end

        $display("TB INFO sweep %0s: N_in=%0d N_safe=%0d V2Pai_mV=%0d Vref_code=%0d ao_min=%0d ao_max=%0d changes=%0d raw_changes=%0d min_ao_gap=%0d",
                 label, n_in, dut.cfg_n_safe, v2pai_mv_in, dut.cfg_vdaref_code,
                 min_ao, max_ao, changes, raw_changes, min_ao_gap);
    end
endtask

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cfg_apply = 1'b0;
    cfg_N = 10'd340;
    cfg_V2Pai_mV = 16'd1800;
    cfg_FBK = 8'd100;
    cfg_FBK2 = 8'd32;
    ai_map_mode = 2'b01;
    ai0_raw = 16'h2000;
    errors = 0;

    $dumpfile("sim/icarus/tb_lv_adapter_config_sweep.vcd");
    $dumpvars(0, tb_lv_adapter_config_sweep);

    run_case(10'd0,    16'd1800, "N zero uses default");
    run_case(10'd50,   16'd1800, "N below min");
    run_case(10'd340,  16'd1800, "nominal");
    run_case(10'd341,  16'd1800, "odd N coerced even");
    run_case(10'd243,  16'd1800, "N 243 coerced to 242");
    run_case(10'd400,  16'd500,  "amp input limit");
    run_case(10'd1022, 16'd2500, "high safe limits");
    run_case(10'd1023, 16'd3000, "clamped high");

    if (errors == 0)
        $display("TB PASS sweep: configuration sweep completed");
    else
        $display("TB FAIL sweep total_errors=%0d", errors);

    $finish;
end

endmodule


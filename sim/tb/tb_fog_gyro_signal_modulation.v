`timescale 1ns/1ps

module tb_fog_gyro_signal_modulation;

reg         clk;
reg         rst_n;
reg         cfg_apply;
reg  [9:0]  cfg_N;
reg  [13:0] cfg_VDARef;
reg  [7:0]  cfg_FBK;
reg  [1:0]  ai_map_mode;
reg  [15:0] ai0_raw;

wire [11:0] adin_mapped;
wire        ready;
wire        adclk;
wire        daclk;
wire [15:0] daout;
wire [15:0] vref_word;
wire        sdaout;
wire        sdaclk;
wire        sdacs;
wire        sp;
wire        sn;
wire [1:0]  state_dbg;
wire [8:0]  counter_dbg;
wire [9:0]  counterN_dbg;
wire [11:0] tau_dbg;
wire [31:0] intsout_dbg;
wire [31:0] drotate_dbg;
wire [31:0] dvref_dbg;

integer errors;
integer cycles_after_ready;
integer gyro_segment;
integer state_seen_mask;
integer ao0_change_count;
integer state_count [0:3];
integer state_sum [0:3];
integer seg_count [0:2];
integer seg_sum [0:2];
integer log_fd;
integer idx;
integer drift_code;
integer gyro_code;
integer signed_code;
integer avg_state0;
integer avg_state1;
integer avg_state2;
integer avg_state3;
integer avg_seg1;
integer avg_seg2;
reg [15:0] daout_prev;

ni5781_ai_to_adin12 u_map (
    .ai_raw(ai0_raw),
    .map_mode(ai_map_mode),
    .adin(adin_mapped)
);

fog_core_ni7966r dut (
    .clk(clk),
    .rst_n(rst_n),
    .cfg_apply(cfg_apply),
    .cfg_N(cfg_N),
    .cfg_VDARef(cfg_VDARef),
    .cfg_FBK(cfg_FBK),
    .adin(adin_mapped),
    .ready(ready),
    .adclk(adclk),
    .daclk(daclk),
    .daout(daout),
    .vref_word(vref_word),
    .sdaout(sdaout),
    .sdaclk(sdaclk),
    .sdacs(sdacs),
    .sp(sp),
    .sn(sn),
    .state_dbg(state_dbg),
    .counter_dbg(counter_dbg),
    .counterN_dbg(counterN_dbg),
    .tau_dbg(tau_dbg),
    .intsout_dbg(intsout_dbg),
    .drotate_dbg(drotate_dbg),
    .dvref_dbg(dvref_dbg)
);

always #12.5 clk = ~clk;

always @(posedge clk) begin
    if (!rst_n || !ready) begin
        ai0_raw <= 16'd0;
    end else begin
        if (cycles_after_ready < 2000)
            gyro_code = 0;
        else if (cycles_after_ready < 4000)
            gyro_code = 180;
        else if (cycles_after_ready < 6000)
            gyro_code = -180;
        else
            gyro_code = 0;

        drift_code = (cycles_after_ready % 96) - 48;

        case (state_dbg)
            2'b00: signed_code = gyro_code + drift_code;
            2'b01: signed_code = -gyro_code + drift_code;
            2'b10: signed_code = -gyro_code + drift_code;
            default: signed_code = gyro_code + drift_code;
        endcase

        ai0_raw <= signed_code <<< 2;
    end
end

always @(posedge clk) begin
    if (!ready) begin
        cycles_after_ready <= 0;
        gyro_segment <= 0;
        state_seen_mask <= 0;
        ao0_change_count <= 0;
        daout_prev <= 16'h0000;
    end else begin
        cycles_after_ready <= cycles_after_ready + 1;
        state_seen_mask[state_dbg] <= 1'b1;

        if (cycles_after_ready < 2000)
            gyro_segment <= 0;
        else if (cycles_after_ready < 4000)
            gyro_segment <= 1;
        else if (cycles_after_ready < 6000)
            gyro_segment <= 2;
        else
            gyro_segment <= 0;

        if (^daout === 1'bx) begin
            $display("TB FAIL gyro: daout has X at t=%0t", $time);
            errors <= errors + 1;
        end

        if (^adin_mapped === 1'bx) begin
            $display("TB FAIL gyro: adin_mapped has X at t=%0t", $time);
            errors <= errors + 1;
        end

        if (daout !== daout_prev) begin
            ao0_change_count <= ao0_change_count + 1;
            daout_prev <= daout;

            if (log_fd != 0) begin
                $fdisplay(log_fd, "%0t,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                          $time, cycles_after_ready, gyro_segment, state_dbg,
                          signed_code, adin_mapped, drotate_dbg, daout);
            end

            if (cycles_after_ready >= 2300 && cycles_after_ready < 3800) begin
                state_count[state_dbg] <= state_count[state_dbg] + 1;
                state_sum[state_dbg] <= state_sum[state_dbg] + daout;
                seg_count[1] <= seg_count[1] + 1;
                seg_sum[1] <= seg_sum[1] + daout;
            end

            if (cycles_after_ready >= 4300 && cycles_after_ready < 5800) begin
                seg_count[2] <= seg_count[2] + 1;
                seg_sum[2] <= seg_sum[2] + daout;
            end
        end
    end
end

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    cfg_apply = 1'b0;
    cfg_N = 10'd170;
    cfg_VDARef = 14'd13280;
    cfg_FBK = 8'd100;
    ai_map_mode = 2'b01;
    ai0_raw = 16'd0;
    errors = 0;
    cycles_after_ready = 0;
    gyro_segment = 0;
    state_seen_mask = 0;
    ao0_change_count = 0;
    daout_prev = 16'h0000;
    drift_code = 0;
    gyro_code = 0;
    signed_code = 0;
    avg_state0 = 0;
    avg_state1 = 0;
    avg_state2 = 0;
    avg_state3 = 0;
    avg_seg1 = 0;
    avg_seg2 = 0;

    for (idx = 0; idx < 4; idx = idx + 1) begin
        state_count[idx] = 0;
        state_sum[idx] = 0;
    end

    for (idx = 0; idx < 3; idx = idx + 1) begin
        seg_count[idx] = 0;
        seg_sum[idx] = 0;
    end

    log_fd = $fopen("sim/icarus/gyro_modulation_samples.csv", "w");
    if (log_fd != 0)
        $fdisplay(log_fd, "time_ns,cycle,segment,state,gyro_signed_code,adin_mapped,drotate_dbg,daout");

    $dumpfile("sim/icarus/tb_fog_gyro_signal_modulation.vcd");
    $dumpvars(0, tb_fog_gyro_signal_modulation);

    #100;
    rst_n = 1'b1;

    repeat (8) @(posedge clk);
    cfg_apply = 1'b1;
    @(posedge clk);
    cfg_apply = 1'b0;

    repeat (7000) @(posedge clk);

    if (ready !== 1'b1) begin
        $display("TB FAIL gyro: ready never asserted");
        errors = errors + 1;
    end

    if ((state_seen_mask & 4'b1111) != 4'b1111) begin
        $display("TB FAIL gyro: four-state sequence incomplete mask=0x%0h", state_seen_mask);
        errors = errors + 1;
    end

    if (ao0_change_count < 16) begin
        $display("TB FAIL gyro: daout changed too few times count=%0d", ao0_change_count);
        errors = errors + 1;
    end

    for (idx = 0; idx < 4; idx = idx + 1) begin
        if (state_count[idx] == 0) begin
            $display("TB FAIL gyro: no modulation samples captured for state=%0d", idx);
            errors = errors + 1;
        end
    end

    if (state_count[0] != 0) avg_state0 = state_sum[0] / state_count[0];
    if (state_count[1] != 0) avg_state1 = state_sum[1] / state_count[1];
    if (state_count[2] != 0) avg_state2 = state_sum[2] / state_count[2];
    if (state_count[3] != 0) avg_state3 = state_sum[3] / state_count[3];
    if (seg_count[1] != 0) avg_seg1 = seg_sum[1] / seg_count[1];
    if (seg_count[2] != 0) avg_seg2 = seg_sum[2] / seg_count[2];

    if (!(avg_state0 > avg_state1 && avg_state3 > avg_state1 && avg_state1 > avg_state2)) begin
        $display("TB FAIL gyro: modulation level ordering unexpected s0=%0d s1=%0d s2=%0d s3=%0d",
                 avg_state0, avg_state1, avg_state2, avg_state3);
        errors = errors + 1;
    end

    if (((avg_seg1 - avg_seg2) < 80) && ((avg_seg2 - avg_seg1) < 80)) begin
        $display("TB FAIL gyro: positive/negative gyro segments too similar avg_pos=%0d avg_neg=%0d",
                 avg_seg1, avg_seg2);
        errors = errors + 1;
    end

    if (errors == 0) begin
        $display("TB PASS gyro: state_avg={%0d,%0d,%0d,%0d} seg_avg_pos=%0d seg_avg_neg=%0d ao0_changes=%0d",
                 avg_state0, avg_state1, avg_state2, avg_state3,
                 avg_seg1, avg_seg2, ao0_change_count);
    end else begin
        $display("TB FAIL gyro total_errors=%0d", errors);
    end

    if (log_fd != 0)
        $fclose(log_fd);

    $finish;
end

endmodule

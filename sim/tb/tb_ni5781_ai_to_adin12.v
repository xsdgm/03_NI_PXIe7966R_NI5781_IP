`timescale 1ns/1ps

module tb_ni5781_ai_to_adin12;

reg  [15:0] ai_raw;
reg  [1:0]  map_mode;
wire [11:0] adin;

integer errors;

ni5781_ai_to_adin12 dut (
    .ai_raw(ai_raw),
    .map_mode(map_mode),
    .adin(adin)
);

task expect;
    input [15:0] in_ai_raw;
    input [1:0]  in_map_mode;
    input [11:0] expected_adin;
    begin
        ai_raw   = in_ai_raw;
        map_mode = in_map_mode;
        #1;
        if (adin !== expected_adin) begin
            $display("TB FAIL mapper: mode=%0d ai_raw=0x%04h expected=0x%03h got=0x%03h",
                     in_map_mode, in_ai_raw, expected_adin, adin);
            errors = errors + 1;
        end
    end
endtask

initial begin
    errors = 0;
    ai_raw = 16'h0000;
    map_mode = 2'b00;

    $dumpfile("sim/icarus/tb_ni5781_ai_to_adin12.vcd");
    $dumpvars(0, tb_ni5781_ai_to_adin12);

    expect(16'h0ABC, 2'b00, 12'hABC);
    expect(16'h0000, 2'b01, 12'd2048);
    expect(16'h1FFC, 2'b01, 12'd4095);
    expect(16'hE000, 2'b01, 12'd0);
    expect(16'h3FFC, 2'b10, 12'hFFF);
    expect(16'h7FFF, 2'b11, 12'd4095);
    expect(16'h8000, 2'b11, 12'd0);

    if (errors == 0)
        $display("TB PASS mapper");
    else
        $display("TB FAIL mapper total_errors=%0d", errors);

    $finish;
end

endmodule

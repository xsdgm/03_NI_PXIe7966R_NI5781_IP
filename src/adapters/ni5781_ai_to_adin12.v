// NI 5781 AI sample mapper.
//
// The original algorithm expects a 12-bit ADC code at `adin[11:0]`.
// NI 5781 AI nodes provide samples as I16 values while the ADC resolution is 14 bit.
// This helper keeps the original core untouched and makes the LabVIEW-side mapping explicit.
//
// map_mode:
//   2'b00: legacy direct mapping, keep ai_raw[11:0]
//   2'b01: signed I16 carrying a 14-bit value, convert to 12-bit offset-binary
//          by arithmetic right shift 2 and adding midscale 2048
//   2'b10: raw bit extraction ai_raw[13:2]
//   2'b11: signed I16 left-justified style fallback, arithmetic right shift 4
//          and add midscale 2048
module ni5781_ai_to_adin12(
    input  wire [15:0] ai_raw,
    input  wire [1:0]  map_mode,
    output reg  [11:0] adin
);

reg signed [15:0] mapped_tmp;

always @* begin
    case (map_mode)
        2'b00: begin
            adin = ai_raw[11:0];
        end

        2'b01: begin
            mapped_tmp = ($signed(ai_raw) >>> 2) + 16'sd2048;
            if (mapped_tmp < 0)
                adin = 12'd0;
            else if (mapped_tmp > 16'sd4095)
                adin = 12'd4095;
            else
                adin = mapped_tmp[11:0];
        end

        2'b10: begin
            adin = ai_raw[13:2];
        end

        default: begin
            mapped_tmp = ($signed(ai_raw) >>> 4) + 16'sd2048;
            if (mapped_tmp < 0)
                adin = 12'd0;
            else if (mapped_tmp > 16'sd4095)
                adin = 12'd4095;
            else
                adin = mapped_tmp[11:0];
        end
    endcase
end

endmodule

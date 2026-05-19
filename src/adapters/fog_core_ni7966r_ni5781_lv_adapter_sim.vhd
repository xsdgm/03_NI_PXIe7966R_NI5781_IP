library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fog_core_ni7966r_ni5781_lv_adapter is
    port (
        clk          : in  std_logic;
        rst_n        : in  std_logic;
        cfg_apply    : in  std_logic;
        cfg_N        : in  std_logic_vector(9 downto 0);
        cfg_V2Pai_mV : in  std_logic_vector(15 downto 0);
        cfg_FBK      : in  std_logic_vector(7 downto 0);
        cfg_FBK2     : in  std_logic_vector(7 downto 0);
        ai_map_mode  : in  std_logic_vector(1 downto 0);
        ai0_raw      : in  std_logic_vector(15 downto 0);
        ao0_raw      : out std_logic_vector(15 downto 0);
        ao1_raw      : out std_logic_vector(15 downto 0);
        sp_sn_value  : out std_logic_vector(15 downto 0);
        status_ready : out std_logic;
        state_dbg    : out std_logic_vector(1 downto 0);
        adin_dbg     : out std_logic_vector(11 downto 0)
    );
end entity;

architecture behavioral of fog_core_ni7966r_ni5781_lv_adapter is
    signal state : unsigned(1 downto 0) := (others => '0');
    signal counter : unsigned(9 downto 0) := (others => '0');
    signal cfg_n_safe : unsigned(9 downto 0) := to_unsigned(170, 10);
    signal adin_mapped : unsigned(11 downto 0) := (others => '0');
    signal vref_word : unsigned(15 downto 0) := (others => '0');
    signal base_word : unsigned(15 downto 0) := (others => '0');
    signal mod_word : unsigned(15 downto 0) := (others => '0');
    signal loop_accum : signed(31 downto 0) := (others => '0');
    signal scale_busy : std_logic := '0';
    signal scale_phase : integer range 0 to 32 := 0;
    signal scale_mod_latch : unsigned(15 downto 0) := (others => '0');
    signal scale_vref_latch : unsigned(15 downto 0) := (others => '0');
    signal scale_product1 : unsigned(31 downto 0) := (others => '0');
    signal scale_product2 : unsigned(48 downto 0) := (others => '0');
    signal ao0_raw_r : std_logic_vector(15 downto 0) := (others => '0');
    signal ao1_raw_r : std_logic_vector(15 downto 0) := (others => '0');

    constant AO0_RECIP_Q31 : unsigned(15 downto 0) := to_unsigned(40427, 16);
    constant AO0_ROUND_Q31 : unsigned(48 downto 0) := to_unsigned(1073741824, 49);

    function clamp12(value : integer) return unsigned is
    begin
        if value < 0 then
            return to_unsigned(0, 12);
        elsif value > 4095 then
            return to_unsigned(4095, 12);
        else
            return to_unsigned(value, 12);
        end if;
    end function;

begin
    process(cfg_N)
        variable n_tmp : integer;
    begin
        n_tmp := to_integer(unsigned(cfg_N));
        if n_tmp < 68 then
            cfg_n_safe <= to_unsigned(68, 10);
        elsif n_tmp > 1022 then
            cfg_n_safe <= to_unsigned(1022, 10);
        else
            cfg_n_safe <= unsigned(cfg_N);
        end if;
    end process;

    process(clk, rst_n)
        variable half_count : integer;
        variable terminal_count : integer;
        variable ai_error : integer;
        variable drive : integer;
    begin
        if rst_n = '0' then
            state <= (others => '0');
            counter <= (others => '0');
            loop_accum <= (others => '0');
        elsif rising_edge(clk) then
            half_count := to_integer(cfg_n_safe) / 2;
            if state(0) = '0' then
                terminal_count := half_count + (to_integer(cfg_n_safe) mod 2);
            else
                terminal_count := half_count;
            end if;

            if to_integer(counter) >= terminal_count then
                counter <= to_unsigned(1, 10);
                state <= state + 1;

                ai_error := to_integer(adin_mapped) - 2048;
                drive := ai_error * (to_integer(unsigned(cfg_FBK)) + to_integer(unsigned(cfg_FBK2)));
                loop_accum <= loop_accum + to_signed(drive, 32);
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    process(ai0_raw, ai_map_mode)
        variable mapped_tmp : integer;
    begin
        case ai_map_mode is
            when "00" =>
                adin_mapped <= unsigned(ai0_raw(11 downto 0));
            when "01" =>
                mapped_tmp := to_integer(shift_right(signed(ai0_raw), 2)) + 2048;
                adin_mapped <= clamp12(mapped_tmp);
            when "10" =>
                adin_mapped <= unsigned(ai0_raw(13 downto 2));
            when others =>
                mapped_tmp := to_integer(shift_right(signed(ai0_raw), 4)) + 2048;
                adin_mapped <= clamp12(mapped_tmp);
        end case;
    end process;

    process(cfg_V2Pai_mV)
        variable vref_tmp : integer;
        variable v2pai_limited : integer;
    begin
        if to_integer(unsigned(cfg_V2Pai_mV)) > 2500 then
            v2pai_limited := 2500;
        else
            v2pai_limited := to_integer(unsigned(cfg_V2Pai_mV));
        end if;
        vref_tmp := (v2pai_limited * 26842 + 2048) / 4096;
        if vref_tmp > 16383 then
            vref_word <= to_unsigned(65532, 16);
        else
            vref_word <= to_unsigned(vref_tmp * 4, 16);
        end if;
    end process;

    process(state)
    begin
        case state is
            when "00" =>
                base_word <= to_unsigned(23254, 16);
            when "01" =>
                base_word <= to_unsigned(2114, 16);
            when "10" =>
                base_word <= to_unsigned(0, 16);
            when others =>
                base_word <= to_unsigned(21140, 16);
        end case;
    end process;

    mod_word <= unsigned(signed(base_word) + resize(loop_accum(26 downto 11), 16));

    process(clk, rst_n)
        variable recip_index : integer range 0 to 15;
    begin
        if rst_n = '0' then
            scale_busy <= '0';
            scale_phase <= 0;
            scale_mod_latch <= (others => '0');
            scale_vref_latch <= (others => '0');
            scale_product1 <= (others => '0');
            scale_product2 <= (others => '0');
            ao0_raw_r <= (others => '0');
            ao1_raw_r <= (others => '0');
        elsif rising_edge(clk) then
            if scale_busy = '0' then
                scale_busy <= '1';
                scale_phase <= 0;
                scale_mod_latch <= mod_word;
                scale_vref_latch <= vref_word;
                scale_product1 <= (others => '0');
                scale_product2 <= (others => '0');
            elsif scale_phase < 16 then
                if scale_vref_latch(scale_phase) = '1' then
                    scale_product1 <= scale_product1 +
                                      shift_left(resize(scale_mod_latch, 32), scale_phase);
                end if;
                scale_phase <= scale_phase + 1;
            elsif scale_phase < 32 then
                recip_index := scale_phase - 16;
                if recip_index = 0 then
                    scale_product2 <= AO0_ROUND_Q31;
                end if;
                if AO0_RECIP_Q31(recip_index) = '1' then
                    if recip_index = 0 then
                        scale_product2 <= AO0_ROUND_Q31 + resize(scale_product1, 49);
                    else
                        scale_product2 <= scale_product2 +
                                          shift_left(resize(scale_product1, 49), recip_index);
                    end if;
                end if;
                scale_phase <= scale_phase + 1;
            else
                if scale_product2(48) = '1' or scale_product2(47) = '1' then
                    ao0_raw_r <= (others => '1');
                else
                    ao0_raw_r <= std_logic_vector(scale_product2(46 downto 31));
                end if;
                scale_busy <= '0';
            end if;
            ao1_raw_r <= std_logic_vector(mod_word);
        end if;
    end process;

    ao0_raw      <= ao0_raw_r;
    ao1_raw      <= ao1_raw_r;
    sp_sn_value  <= std_logic_vector(to_signed(1, 16)) when state = "01" else
                    std_logic_vector(to_signed(-1, 16)) when state = "10" else
                    std_logic_vector(to_signed(0, 16));
    status_ready <= rst_n;
    state_dbg    <= std_logic_vector(state);
    adin_dbg     <= std_logic_vector(adin_mapped);
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fog_core_ni7966r_ni5781_lv_adapter is
    port (
        clk          : in  std_logic;
        rst_n        : in  std_logic;
        cfg_apply    : in  std_logic;
        cfg_N        : in  std_logic_vector(9 downto 0);
        cfg_VDARef   : in  std_logic_vector(13 downto 0);
        cfg_FBK      : in  std_logic_vector(7 downto 0);
        cfg_FBK2     : in  std_logic_vector(7 downto 0);
        ai_map_mode  : in  std_logic_vector(1 downto 0);
        ai0_raw      : in  std_logic_vector(15 downto 0);
        ai1_raw      : in  std_logic_vector(15 downto 0);
        ao0_raw      : out std_logic_vector(15 downto 0);
        ao1_raw      : out std_logic_vector(15 downto 0);
        dio_sp       : out std_logic;
        dio_sn       : out std_logic;
        status_ready : out std_logic;
        state_dbg    : out std_logic_vector(1 downto 0);
        adin_dbg     : out std_logic_vector(11 downto 0)
    );
end entity;

architecture behavioral of fog_core_ni7966r_ni5781_lv_adapter is
    signal state : unsigned(1 downto 0) := (others => '0');
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= (others => '0');
        elsif rising_edge(clk) then
            state <= state + 1;
        end if;
    end process;

    ao0_raw      <= ai0_raw;
    ao1_raw      <= "00" & cfg_VDARef;
    dio_sp       <= state(0);
    dio_sn       <= not state(0);
    status_ready <= rst_n;
    state_dbg    <= std_logic_vector(state);
    adin_dbg     <= ai0_raw(15 downto 4) when ai_map_mode = "00" else ai0_raw(11 downto 0);
end architecture;

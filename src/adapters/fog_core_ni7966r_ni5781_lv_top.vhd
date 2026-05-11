library ieee;
use ieee.std_logic_1164.all;

entity fog_core_ni7966r_ni5781_lv_top is
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
        sp_sn_value  : out std_logic_vector(15 downto 0);
        status_ready : out std_logic;
        state_dbg    : out std_logic_vector(1 downto 0);
        adin_dbg     : out std_logic_vector(11 downto 0)
    );
end entity;

architecture rtl of fog_core_ni7966r_ni5781_lv_top is
    component fog_core_ni7966r_ni5781_lv_adapter
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
            sp_sn_value  : out std_logic_vector(15 downto 0);
            status_ready : out std_logic;
            state_dbg    : out std_logic_vector(1 downto 0);
            adin_dbg     : out std_logic_vector(11 downto 0)
        );
    end component;

    attribute box_type : string;
    attribute box_type of fog_core_ni7966r_ni5781_lv_adapter : component is "black_box";
begin
    u_ngc : fog_core_ni7966r_ni5781_lv_adapter
        port map (
            clk          => clk,
            rst_n        => rst_n,
            cfg_apply    => cfg_apply,
            cfg_N        => cfg_N,
            cfg_V2Pai_mV => cfg_V2Pai_mV,
            cfg_FBK      => cfg_FBK,
            cfg_FBK2     => cfg_FBK2,
            ai_map_mode  => ai_map_mode,
            ai0_raw      => ai0_raw,
            ao0_raw      => ao0_raw,
            sp_sn_value  => sp_sn_value,
            status_ready => status_ready,
            state_dbg    => state_dbg,
            adin_dbg     => adin_dbg
        );
end architecture;

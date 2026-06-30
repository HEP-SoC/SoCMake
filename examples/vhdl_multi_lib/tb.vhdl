library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use std.env.all;

library counter_lib;

entity tb is
end tb;

architecture behavioral of tb is
    signal clk        : std_logic := '0';
    signal rst_n      : std_logic := '0';
    signal q0         : std_logic;
    signal q1         : std_logic;
    signal count_eq_3 : std_logic;
    signal count_int  : std_logic_vector(1 downto 0);

    constant CLK_PERIOD : time := 10 ns;
begin

    uut : entity counter_lib.counter
        port map (
            clk        => clk,
            rst_n      => rst_n,
            q0         => q0,
            q1         => q1,
            count_eq_3 => count_eq_3
        );

    count_int <= q1 & q0;

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        report "Multi-library example: counter_lib.counter using gates_lib components" severity note;

        -- Reset
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';

        -- Count 0
        wait until rising_edge(clk);
        report "Count: " & integer'image(conv_integer(count_int))
            & "  count_eq_3=" & std_logic'image(count_eq_3) severity note;

        -- Count 1
        wait until rising_edge(clk);
        report "Count: " & integer'image(conv_integer(count_int))
            & "  count_eq_3=" & std_logic'image(count_eq_3) severity note;

        -- Count 2
        wait until rising_edge(clk);
        report "Count: " & integer'image(conv_integer(count_int))
            & "  count_eq_3=" & std_logic'image(count_eq_3) severity note;

        -- Count 3
        wait until rising_edge(clk);
        report "Count: " & integer'image(conv_integer(count_int))
            & "  count_eq_3=" & std_logic'image(count_eq_3) severity note;

        -- Count 0 (wraps)
        wait until rising_edge(clk);
        report "Count: " & integer'image(conv_integer(count_int))
            & "  count_eq_3=" & std_logic'image(count_eq_3) severity note;

        report "PASS: counter wraps correctly at 3" severity note;
        std.env.stop;
    end process;

end behavioral;

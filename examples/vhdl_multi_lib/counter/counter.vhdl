library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library gates_lib;

entity counter is
    port (
        clk        : in  std_logic;
        rst_n      : in  std_logic;
        q0         : out std_logic;
        q1         : out std_logic;
        count_eq_3 : out std_logic
    );
end counter;

architecture structural of counter is
    signal ff0, nff0      : std_logic;
    signal ff1, nff1      : std_logic;
    signal max_count      : std_logic;
    signal ff1_toggle_en  : std_logic;
begin

    -- T flip-flop bit 0: toggles every clock
    u_xor0 : entity gates_lib.xor_gate
        port map (
            a => ff0,
            b => '1',
            y => nff0
        );

    ff0_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            ff0 <= '0';
        elsif rising_edge(clk) then
            ff0 <= nff0;
        end if;
    end process;

    -- T flip-flop bit 1: toggles only when ff0 is 1
    u_xor1 : entity gates_lib.xor_gate
        port map (
            a => ff1,
            b => ff0,            -- toggle when bit 0 is high
            y => nff1
        );

    ff1_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            ff1 <= '0';
        elsif rising_edge(clk) then
            ff1 <= nff1;
        end if;
    end process;

    -- Combinational flag: true when count reaches 3
    u_and : entity gates_lib.and_gate
        port map (
            a => ff0,
            b => ff1,
            y => max_count
        );

    q0         <= ff0;
    q1         <= ff1;
    count_eq_3 <= max_count;

end structural;

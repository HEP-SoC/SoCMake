library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_adder is
end entity;

architecture sim of tb_adder is
    -- DUT signals
    signal a : unsigned(4 downto 0);
    signal b : unsigned(4 downto 0);
    signal o : unsigned(4 downto 0);
begin
    -- Instantiate DUT
    uut: entity work.adder
        port map (
            NUM1 => a,
            NUM2 => b,
            SUM  => o
        );

    -- Test process
    stim_proc: process
    begin
        a <= to_unsigned(5, a'length);
        b <= to_unsigned(10, b'length);
        wait for 1 ns;

        report "Hello world, from SoCMake build system";
        report integer'image(to_integer(a)) & " + " &
               integer'image(to_integer(b)) & " = " &
               integer'image(to_integer(o));

        assert (o = to_unsigned(15, o'length))
            report "Test failed: expected 15"
            severity failure;

        wait; -- stop simulation
    end process;
end architecture;

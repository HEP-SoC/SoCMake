library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
-- Testbench entity has no ports
end entity tb;

architecture Behavioral of tb is
    -- Signal declarations for testbench
    signal a, b, o : std_logic_vector(4 downto 0);
begin

    -- Instantiation of the adder
    adder_i : entity work.adder
        port map (
            NUM1 => a,
            NUM2 => b,
            SUM => o
        );

    -- Testbench process
    stim_proc : process
    begin
        -- Initialize values
        a <= std_logic_vector(to_unsigned(5, 5));
        b <= std_logic_vector(to_unsigned(10, 5));
        wait for 1 ns;

        -- Display the result (VHDL equivalent to $display)
        report "Hello world, from SoCMake build system";
        report integer'image(to_integer(unsigned(a))) & " + " & integer'image(to_integer(unsigned(b))) & " = " & integer'image(to_integer(unsigned(o)))  ;

        -- Finish the simulation
        wait;
    end process stim_proc;

end architecture Behavioral;

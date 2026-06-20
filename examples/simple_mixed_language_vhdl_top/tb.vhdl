library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb is
end tb;

architecture behavioral of tb is

    signal a, b : std_logic_vector(4 downto 0);
    signal o    : std_logic_vector(4 downto 0);

    component adder is
        port (
            NUM1 : in  std_logic_vector(4 downto 0);
            NUM2 : in  std_logic_vector(4 downto 0);
            SUM  : out std_logic_vector(4 downto 0)
        );
    end component;

begin

    adder_i : adder
        port map (
            NUM1 => a,
            NUM2 => b,
            SUM  => o
        );

    process
    begin
        a <= "00101";  -- 5
        b <= "01010";  -- 10
        wait for 1 ns;

        report "Hello world, from SoCMake build system" severity note;
        report integer'image(to_integer(unsigned(a))) & " + "
            & integer'image(to_integer(unsigned(b))) & " = "
            & integer'image(to_integer(unsigned(o))) severity note;

        wait;
    end process;

end behavioral;

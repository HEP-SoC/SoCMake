library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder is
    Port (
        NUM1 : in  unsigned(4 downto 0);
        NUM2 : in  unsigned(4 downto 0);
        SUM  : out unsigned(4 downto 0)
    );
end adder;

architecture Behavioral of adder is
begin
    SUM <= NUM1 + NUM2;
end Behavioral;

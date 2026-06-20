library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity and_gate is
    port (
        a : in  std_logic;
        b : in  std_logic;
        y : out std_logic
    );
end and_gate;

architecture behavioral of and_gate is
begin
    y <= a and b;
end behavioral;

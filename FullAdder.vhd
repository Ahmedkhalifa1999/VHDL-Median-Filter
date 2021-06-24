library ieee;
use ieee.std_logic_1164.all;

entity FullAdder is
	port(
		A, B, Cin  : in std_logic;
		Sum, Cout  : out std_logic
	);
end entity;

architecture RTL of FullAdder is
	
begin
	Sum <= A xor B xor Cin;
	Cout <= ((A xor B) and Cin) or (A and B);
end architecture;

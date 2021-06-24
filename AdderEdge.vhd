library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--6-input 1-bit Adder
entity AdderEdge is port(
	Input : in std_logic_vector(5 downto 0);
	Output : out unsigned(2 downto 0)
);
end entity;

architecture behavior of AdderEdge is
	component FullAdder port(A, B, Cin : in std_logic; Sum, Cout : out std_logic); end component;
	signal term1 : unsigned(2 downto 0) := (others => '0');
	signal term2 : unsigned(2 downto 0) := (others => '0');
begin
	Add1: FullAdder port map(A => Input(0), B => Input(1), Cin => Input(2), Sum => term1(0), Cout => term1(1));
	Add2: FullAdder port map(A => Input(3), B => Input(4), Cin => Input(5), Sum => term2(0), Cout => term2(1));
	Output <= term1 + term2 ;
end architecture;
	
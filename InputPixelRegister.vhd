library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Parallel Load Serial Output 8-bit Shift Register for 1 Input Pixel
entity InputPixelRegister is port(
	DataIn : in std_logic_vector(7 downto 0);
	clk, wren : in std_logic;
	DataOut : out std_logic 
);
end entity;

architecture RTL of InputPixelRegister is
	signal reg : std_logic_vector(7 downto 0);
begin
	process(clk, wren, DataIn)
	begin
		if(wren = '1') then
			reg <= DataIn;
		elsif(rising_edge(clk)) then
			reg <= reg(6 downto 0) & '0';
		end if;
	end process;
	DataOut <= reg(7);
end architecture;

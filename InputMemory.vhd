library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Connecting InputRegisters to form a memory for input pixels
--Could also be implemented using serial load instead of parallel load (loading 1 row per clock instead of 3)
entity InputMemory is port(
	clk, wren : std_logic;
	DataIn : in std_logic_vector(2399 downto 0);
	DataOut : out std_logic_vector(299 downto 0)
);
end entity;

architecture RTL of InputMemory is 
	component InputPixelRegister port(DataIn : in std_logic_vector(7 downto 0); clk, wren : in std_logic;
									  DataOut : out std_logic); end component;
	signal DataI : std_logic_vector(2399 downto 0);
	signal DataO : std_logic_vector(299 downto 0);
begin
	Memory : for i in 299 downto 0 generate
		Reg : InputPixelRegister port map(DataIn => DataI((i*8)+7 downto i*8), clk => clk, wren => wren,
										  DataOut => DataO(i));
	end generate;
	DataOut <= DataO;
	DataI <= DataIn;
end architecture;

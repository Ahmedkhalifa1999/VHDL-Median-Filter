library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Connecting all parts of the Module (InputMemory, Median and MedianEdge)
entity MedianFilter is port(
	clk, Oregclk, Iregclk, NewRow, mode : in std_logic;
	DataIn : in std_logic_vector(2399 downto 0);
	DataOut : out std_logic_vector(799 downto 0)
);
end entity;

architecture Components of MedianFilter is
	component InputMemory port(
		clk, wren : in std_logic;
		DataIn : in std_logic_vector(2399 downto 0);
		DataOut : out std_logic_vector(299 downto 0)
	); end component;
	component Median port(
		clk, regclk, reset : in std_logic;
		mode : in std_logic; --'0' => Center Pixel, '1' => Edge Pixel
		DataIn : in std_logic_vector(8 downto 0);
		DataOut : out std_logic_vector(7 downto 0)
	); end component;
	component MedianEdge port(
		clk, regclk, reset : in std_logic;
		mode : in std_logic; --'0' => Edge Pixel, '1' => Corner Pixel
		DataIn : in std_logic_vector(5 downto 0);
		DataOut : out std_logic_vector(7 downto 0)
	); end component;
	signal MSBits : std_logic_vector(299 downto 0); --All Median and MedianEdge Input Data from InputMemory
	 --each window corresponds to a Median or MedianEdge unit input
	type windows is array (98 downto 1) of std_logic_vector(8 downto 0);
	signal window : windows;
	signal rightwindow : std_logic_vector(5 downto 0);
	signal leftwindow : std_logic_vector(5 downto 0);
	signal Row1 : std_logic_vector(99 downto 0);
	signal Row2 : std_logic_vector(99 downto 0);
	signal Row3 : std_logic_vector(99 downto 0);
begin
	Row1 <= MSBits(299 downto 200);
	Row2 <= MSBits(199 downto 100);
	Row3 <= MSBits(99 downto 0);
	
	windowcon : for i in 98 downto 1 generate
			window(i) <= Row1(i+1 downto i-1) & Row2(i+1 downto i-1) & Row3(i+1 downto i-1);
	end generate;
	leftwindow <= Row1(99 downto 98) & Row2(99 downto 98) & Row3(99 downto 98);
	rightwindow <= Row1(1 downto 0) & Row2(1 downto 0) & Row3(1 downto 0);
	
	InputMem : InputMemory port map(clk => Iregclk, wren => NewRow, DataIn => DataIn, DataOut => MSBits);
	left : MedianEdge port map(clk => clk, regclk => Oregclk, reset => NewRow, mode => mode,
							   DataIn => leftwindow, DataOut => DataOut(799 downto 792));
	right : MedianEdge port map(clk => clk, regclk => Oregclk, reset => NewRow , mode => mode,
								DataIn => rightwindow, DataOut => DataOut(7 downto 0));
	Middle : for i in 98 downto 1 generate
		MiddleUnit : Median port map(clk => clk, regclk => Oregclk,  reset => NewRow , mode => mode,
									 DataIn => window(i), DataOut => DataOut((i*8)+7 downto i*8));
	end generate;
end architecture;

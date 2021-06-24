library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Trimmed down version of Median for dealing with less inputs
entity MedianEdge is port(
	clk, regclk, reset : in std_logic;
	mode : in std_logic; --'0' => Edge Pixel, '1' => Corner Pixel
	DataIn : in std_logic_vector(5 downto 0);
	DataOut : out std_logic_vector(7 downto 0)
);
end entity;

architecture FSM of MedianEdge is 
	component AdderEdge port(Input : in std_logic_vector(5 downto 0); Output : out unsigned(2 downto 0)); 
	end component;
	signal SelectionGroupSum : unsigned(2 downto 0);
	signal MedianBits : std_logic_vector(5 downto 0);
	signal SelectionGroup : std_logic_vector(5 downto 0);
	signal BitOut : std_logic;
	signal OutReg : std_logic_vector(7 downto 0);
begin
	SelectionGroup <= MedianBits and DataIn;
	Add : AdderEdge port map(Input => SelectionGroup, Output => SelectionGroupSum);
	
	Med : process(clk, reset, mode)
		variable MedianPos : unsigned(1 downto 0) := "11";
	begin
		if(reset = '1') then
			case mode is when '0' => MedianPos := "11";
						 when '1' => MedianPos := "10";
						 when others => MedianPos := "--"; end case;
			MedianBits <= "111111";
		elsif(rising_edge(clk)) then
			case (SelectionGroupSum >= '0' & MedianPos) is
			when true => BitOut <= '1'; MedianBits <= MedianBits and DataIn;
			when false => BitOut <= '0'; MedianBits <= MedianBits and not(DataIn);
						  MedianPos := MedianPos - SelectionGroupSum(1 downto 0);
			when others => BitOut <= '-';
			end case;	
		end if;
	end process;
	
	Reg : process(regclk)
	begin
		if(rising_edge(regclk) and reset = '0') then
			OutReg(7 downto 0) <= OutReg(6 downto 0) & BitOut;
		end if;
	end process;
	DataOut <= OutReg;	
end architecture;
				
			
			
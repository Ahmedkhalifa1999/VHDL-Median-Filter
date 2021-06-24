library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--FSM for generating Median from input window of 8-bit numbers
--Calculates Median in 8 clock cycles
--The number of clock cycles needed to calculate the median can be reduced at the expense of accuracy.
--Doing so would also reduce the number of Input and Output registers needed.
entity Median is port(
	clk, regclk, reset : in std_logic;
	mode : in std_logic; --'0' => Center Pixel, '1' => Edge Pixel
	DataIn : in std_logic_vector(8 downto 0);
	DataOut : out std_logic_vector(7 downto 0)
);
end entity;

architecture FSM of Median is 
	component Adder port(Input : in std_logic_vector(8 downto 0); Output : out unsigned(3 downto 0)); 
	end component;
	signal SelectionGroupSum : unsigned(3 downto 0);
	signal MedianBits : std_logic_vector(8 downto 0);
	signal SelectionGroup : std_logic_vector(8 downto 0);
	signal BitOut : std_logic;
	signal OutReg : std_logic_vector(7 downto 0);
begin
	SelectionGroup <= MedianBits and DataIn;
	Add : Adder port map(Input => SelectionGroup, Output => SelectionGroupSum);
	
	Med : process(clk, reset, mode)
		variable MedianPos : unsigned(2 downto 0) := "101";
	begin
		if(reset = '1') then
			case mode is when '0' => MedianPos := "101";
						 when '1' => MedianPos := "011";
						 when others => MedianPos := "---"; end case;
			MedianBits <= "111111111";
		elsif(rising_edge(clk)) then
			case (SelectionGroupSum >= '0' & MedianPos) is
			when true => BitOut <= '1'; MedianBits <= MedianBits and DataIn;
			when false => BitOut <= '0'; MedianBits <= MedianBits and not(DataIn);
						  MedianPos := MedianPos - SelectionGroupSum(2 downto 0);
			when others => BitOut <= '-';
			end case;	
		end if;
	end process;
	
	--Serial Load Parallel Output Shift Register for storing output pixel
	Reg : process(regclk)
	begin
		if(rising_edge(regclk) and reset = '0') then
			OutReg(7 downto 0) <= OutReg(6 downto 0) & BitOut;
		end if;
	end process;
	DataOut <= OutReg;	
end architecture;
				
			
			
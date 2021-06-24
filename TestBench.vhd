library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;


entity TestBench is
end entity;
	
architecture behavior of TestBench is
	constant Inpath : string := "C:/Users/ahmed/Desktop/UnfilteredImage.txt"; --Input Image Path
	constant Outpath : string := "C:/Users/ahmed/Desktop/FilteredImage.txt"; --Output Image Path
	
	component MedianFilter port(
		clk, Oregclk, Iregclk, NewRow, mode : in std_logic; 
		DataIn : in std_logic_vector(2399 downto 0);
		DataOut : out std_logic_vector(799 downto 0)
	); end component;
	signal clk : std_logic;
	signal Oregclk : std_logic;
	signal Iregclk : std_logic; 
	signal NewRow : std_logic;
	signal mode : std_logic;
	signal DataIn : std_logic_vector(2399 downto 0);
	signal DataOut : std_logic_vector(799 downto 0);
	file input : text;
	file output : text;
begin
	UUT : MedianFilter port map(clk => clk, Oregclk => Oregclk, Iregclk => Iregclk, NewRow => NewRow,mode => mode, 
								DataIn => DataIn, DataOut => DataOut);
	
	Iclock : process
	begin
		Iregclk <= '0';
		wait for 1 ns;
		loop
			Iregclk <= '1';
			wait for 10 ns;
			Iregclk <= '0';
			wait for 10 ns;
		end loop;
	end process;
	clock : process
	begin
		clk <= '0';
		wait for 2 ns;
		loop
			clk <= '1';
			wait for 10 ns;
			clk <= '0';
			wait for 10 ns;
		end loop;
	end process;
	Oclock : process
	begin
		Oregclk <= '0';
		wait for 3 ns;
		loop
			Oregclk <= '1';
			wait for 10 ns;
			Oregclk <= '0';
			wait for 10 ns;
		end loop;
	end process;
	NewRowclock : process
	begin
		loop
			NewRow <= '1';
			wait for 2 ns;
			NewRow <= '0';
			wait for 158 ns;
		end loop;
	end process;
	
	test : process
		variable Iline : line;
		variable InputRows : std_logic_vector(2399 downto 0);
		variable Oline : line;
		variable OutputRow : std_logic_vector(799 downto 0);
		variable row : integer;
	begin
		file_open(input, Inpath, read_mode);
		file_open(output, Outpath, write_mode);
		
		row := 0;
		while not(endfile(input)) loop
			readline(input, Iline);
			read(Iline, InputRows);
			if (row = 0 or row = 99) then mode <= '1'; else mode <= '0'; end if; row := row + 1;
			DataIn <= InputRows;
			wait for 160 ns;
			OutputRow := DataOut;
			write(Oline, OutputRow);
			writeline(output, Oline);
		end loop;
		
		file_close(input);
		file_close(output);
		
		report("Test Finished");
		wait;
	end process;
	
end architecture;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SPI_Master is
	generic(slaves: integer := 1; d_width: integer:=320); -- transmit and receive data bus width
	port(
			clock, reset_n : IN std_logic;
			enable : IN std_logic; -- Initiate a transaction(0: no transaction)
			clk_div : IN integer; -- Speed setting: This is the number of system clocks per 1/2 period of sclk
			addr : IN integer; -- @ of target slave
			cpol, cpha, cont: in std_logic;
			Tx_data : in std_logic_vector(d_width-1 downto 0); -- data to transmit
			MISO : in std_logic;
			SCLK : buffer std_logic; -- SPI clock
			ss_n : buffer std_logic_vector(slaves-1 downto 0); -- Slave select signals
			Rx_data : out std_logic_vector(d_width-1 downto 0); -- Data received from target slave
			busy : out std_logic;
			MOSI : out std_logic
		);
end SPI_Master ;
architecture Arch_SPI_Master of SPI_Master is

signal setting:std_logic; --Specifier whether write or read??
signal address : integer;
signal data: std_logic_vector(d_width-1 downto 0);
begin
busy <= '0';
--SCLK <= clock / (2 * clk_div);
SPI_SCLK:Process(clock)
   variable temp :integer :=0;
   begin
	if(reset_n = '1' and clock'event and clock= '1') then
		busy <= '0';
		temp := temp +1 ;
		if (temp = clk_div ) then
			SCLK <= '1';
		elsif(temp = (2 * clk_div)) then
			SCLK <= '0';
		else
			temp := 1;
			SCLK <= '1';		
		end if;
	end if;
   end process;
-----------------------------------------------------------------------------------------------------
-- *** The reset_n input port must have a logic high for the SPI master component to operate. ***
-- *** 
-----------------------------------------------------------------------------------------------------
SPI_Transaction:Process(reset_n, clock, Tx_data )
   variable timeClk :integer :=0;
   variable nul :boolean :=True;
   begin	
	if(reset_n = '0')then
		busy <= '1';
		ss_n <= (others => '1');
		MOSI <= 'Z';
		Rx_data <= (OTHERS => '0');
	else
	   for k in 0 to d_width-1 loop
		if Tx_data(k) /= '0' then
			nul := FALSE;
			-- ??? <=> break;  
		end if;
	   end loop;
	   if(nul = TRUE) then
	   --if(Tx_data /= (others=>'0')) then
		if(enable = '1' and clock'event and clock= '1') then
			if(timeClk = 0 )then  --On the first rising edge of clock
				address <= addr;
				data <= Tx_data;
				timeClk := timeClk +1;
			end if;
		end if;
		if(timeClk = 1 and clock'event and clock= '1') then -- On the following clock
			timeClk := 0;
			busy <= '1';
			for i in 0 to d_width -1 loop
				WAIT UNTIL rising_edge (SCLK);
				MOSI <= data(i);
			        data(i) <= MISO;
			end loop;
		end if;
		Rx_data <= data;
		busy <= '0';
	    end if;
	end if;
   end process;

end Arch_SPI_Master;

library�IEEE;
use�IEEE.std_logic_1164.all;
USE ieee.std_logic_arith.all;
use�IEEE.numeric_std.all;

entity SPI_Master is
	generic(slaves: integer := 1; d_width: integer:=8); -- transmit and receive data bus width
	port(
			clock, reset_n : IN std_logic;
			enable : IN std_logic; -- Initiate a transaction(0: no transaction):
				-- Latches in the standard logic values of cpol and cpha at the start of each transaction:
				-- Communication with individual slaves using independent SPI modes.  
			clk_div : IN integer; -- Speed setting: This is the number of system clocks per 1/2 period of sclk
			addr    : IN integer; -- @ of target slave
			cpol, cpha, cont: in std_logic;
			Tx_data : in std_logic_vector(d_width-1 downto 0); -- data to transmit come from CPU
			MISO    : in std_logic;
			SCLK    : buffer std_logic; -- SPI clock
			ss_n    : buffer std_logic_vector(slaves-1 downto 0); -- Slave select signals
			Rx_data : out std_logic_vector(d_width-1 downto 0); -- Data received from target slave(related to MISO) to CPU
			busy    : out std_logic;
			MOSI    : out std_logic
		);  
end SPI_Master ;
architecture Arch_SPI_Master of SPI_Master is
  TYPE machine IS(ready, execute);                           --state machine data type
  SIGNAL state, next_state       : machine;                  --current state
  SIGNAL slave       : INTEGER;                              --slave selected for current transaction
  SIGNAL ctr_clock   : INTEGER :=0 ;                         --*Counter on clock's edges for the SPI_sclk*
  SIGNAL clk_ratio   : INTEGER :=1;                          --current clk_div
  SIGNAL count       : INTEGER;                              --#counter to trigger sclk from system clock
  SIGNAL clk_toggles : INTEGER RANGE 0 TO d_width*2 + 1;     --count spi clock toggles for one transaction(Transmission then reception)
  SIGNAL assert_data : STD_LOGIC;                            --'1' is tx sclk toggle(trasmission), '0' is rx sclk toggle(reception)
  SIGNAL continue    : STD_LOGIC;                            --flag to continue transaction
  SIGNAL rx_buffer   : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0); --receive data buffer
  SIGNAL tx_buffer   : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0); --transmit data buffer
  SIGNAL last_bit_rx : INTEGER RANGE 0 TO d_width*2;         --last rx data bit location


--signal setting:std_logic; --Specifier whether write or read?? 
--signal address : integer; signal data: std_logic_vector(d_width-1 downto 0);
begin
--state <= ready; -- au lieu de busy <= '0';
--SCLK <= clock / (2 * clk_div);  ???? Math op: to_signed(to_integer(signed(X) / signed(Y)),32) ????
-----------------------------------------------------------------------------------------------------
-- *** During reset(Low signal), the component holds the busy port and all ss_n outputs high. ***
-- *** The MOSI output assumes a high impedance state, and the rx_data output port clears.    ***
-----------------------------------------------------------------------------------------------------
SPI_SCLK: Process(reset_n) -- Asynchrone
begin
	if reset_n = '0' then
		busy <= '1'; -- the component(SPI_Master) is not ready
		for i in 0 to slaves-1 loop 
			ss_n(i) <= '1'; -- disable slave n� i
		end loop;
		MOSI <= 'Z';
		Rx_data <= (OTHERS=>'0');
		next_state <= ready;
	end if;
end process;
-----------------------------------------------------------------------------------------------------
-- *** Setting SPI_sclk: Freqeunce_SCLK <= clock / (2 * clk_div); ***
-----------------------------------------------------------------------------------------------------
Clock_Divider: Process(clock) 
begin
	if(reset_n = '1' and enable ='1') then
	  if(rising_edge(clock)) then 
	     ctr_clock <= ctr_clock + 1 ;
	  end if;
	  if(ctr_clock = 2*clk_ratio)then
		if(falling_edge(clock))then
			sclk <= not sclk;
			ctr_clock <= 0;
		else
			sclk <= not sclk;
	   	end if;
	   end if;
	else
	   sclk <= '0';
      end if;
end process;
-----------------------------------------------------------------------------------------------------
-- *** Transaction Process: Configuration + Implementation .                    
-- *** If CPHA is zero, the first data bit is written on the SS falling edge and read on the first SCLK edge.
-- *** If CPHA is one, data is written on the first SCLK edge and read on the second SCLK edge. 
-- => We suppose that SS falling edge and SCLK edge are in the same time => Independly to CPHA  
-----------------------------------------------------------------------------------------------------
Busy_Switch: Process(next_state, sclk)
begin
  state <= next_state;
  if(reset_n = '1' and sclk'EVENT AND sclk = '1') then
		--busy <= '0';
    CASE state IS               --state machine
        WHEN ready =>
          busy <= '0';             --clock out not busy signal
          ss_n <= (OTHERS => '1'); --set all slave select outputs high
          mosi <= 'Z';             --set mosi output high impedance
          continue <= '0';         --clear continue flag( Stop the transaction)

          --user input to initiate transaction
          IF(enable = '1') THEN  
	  -- The component latches the settings, address, and data for a transaction
	  -- on the first rising edge of clock where the enable input is asserted.     
            busy <= '1';             --set busy signal
	    -- *** Correct Configurations ***
            IF(addr < slaves) THEN   --check for valid slave address
              slave <= addr;         --clock in current slave selection if valid
            ELSE
              slave <= 0;            --set to first slave if not valid
            END IF;
	    -- ss_n(slaves) <= '0';  -- *** Enable the addr correspond slave *** Must be on the next edge
            IF(clk_div = 0) THEN     --check for valid spi speed
              clk_ratio <= 1;        --set to maximum speed if zero(~clk_div)
              count <= 1;            --initiate system-to-spi clock counter
            ELSE
              clk_ratio <= clk_div;  --set to input selection if valid
              count <= clk_div;      --initiate system-to-spi clock counter
            END IF;
            --sclk <= to_signed(to_integer(clock) / 2*(clk_ratio)),32); --sclk <= cpol;            --set spi clock polarity (normalm. <=clock / (2 * clk_div);)
            sclk <= cpol;            --Initially
	    assert_data <= NOT cpha; --cpha must be 1 initially:transmit then receive: '1' is tx sclk toggle, '0' is rx sclk toggle
            tx_buffer <= tx_data;    --clock in data for transmit into buffer
            clk_toggles <= 0;        --initiate clock toggle counter for new transaction
            last_bit_rx <= 2*d_width; -- + conv_integer(cpha) - 1; --set last rx data bit position
            state <= execute;        --proceed to execute state
          ELSE
            state <= ready;          --remain in ready state
          END IF;
	WHEN execute =>
	  busy <= '1';        --set busy signal
          ss_n(slave) <= '0'; --set proper slave select output		
	  --system clock to sclk ratio is met
          --*IF(count = clk_ratio) THEN   --tjs Vrai Initialement: vient just de sortir du ready   
            --count <= 1;                     --reset system-to-spi clock counter
           assert_data <= NOT assert_data; --switch transmit/receive indicator
           IF(clk_toggles = 2 * d_width + 1) THEN
             clk_toggles <= 0;               --reset spi clock toggles counter
           ELSE
             clk_toggles <= clk_toggles + 1; --increment spi clock toggles counter (per switch if clk_ratio/=1)
           END IF;
           
           --spi clock toggle needed
	-- No needed clk b'cause Clock divider is defined
           --IF(clk_toggles <= d_width*2 AND ss_n(slave) = '0') THEN --tjs Vrai
           --  sclk <= NOT sclk; --toggle spi clock
           --END IF;
           
           --receive spi clock toggle
           IF(assert_data = '0' AND clk_toggles < last_bit_rx + 1 ) THEN --  AND ss_n(slave) = '0'
             rx_buffer <= rx_buffer(d_width-2 DOWNTO 0) & miso;--shift in received bit: Cancat.
           END IF;
           
           --transmit spi clock toggle
           IF(assert_data = '1' AND clk_toggles < last_bit_rx) THEN -- b'cause Tx then Rx
             mosi <= tx_buffer(d_width-1);                     --clock out data bit
             tx_buffer <= tx_buffer(d_width-2 DOWNTO 0) & '0'; --shift data transmit buffer
           END IF;
           
           --last data receive, but continue
           IF(clk_toggles = last_bit_rx AND cont = '1') THEN 
             tx_buffer <= tx_data;                       --reload transmit buffer
             clk_toggles <= 0; --last_bit_rx - (2*d_width - 1); --reset spi clock toggle counter
             continue <= '1';                            --set continue flag
           END IF;
           
           --normal end of transaction, but continue
           IF(continue = '1') THEN  
             continue <= '0';      --clear continue flag
             busy <= '0';          --clock out signal that first receive data is ready
             rx_data <= rx_buffer; --clock out received data to output port    
           END IF;
           
           --end of transaction
           IF((clk_toggles = 2*d_width -1) AND cont = '0') THEN   
             busy <= '0';             --clock out not busy signal
             ss_n <= (OTHERS => '1'); --set all slave selects high
             mosi <= 'Z';             --set mosi output high impedance
             rx_data <= rx_buffer;    --clock out received data to output port
             state <= ready;          --return to ready state
           ELSE                       --not end of transaction
             state <= execute;        --remain in execute state
           END IF;
          
--          ELSE        --system clock to sclk ratio not met
--            count <= count + 1; --increment counter
--            state <= execute;   --remain in execute state
--          END IF;
    END CASE;
  END IF;
end process;
--------------*** Q: Why wait require Process without parametre ?????? ***---------------------------
-----------------------------------------------------------------------------------------------------
-- *** The reset_n input port must have a logic high for the SPI master component to operate. ***
-- *** 
-----------------------------------------------------------------------------------------------------
--SPI_Transaction:Process --(reset_n, clock, Tx_data )
--variable timeClk :integer :=0;
--variable nul :boolean :=True;
--begin	
--	if(reset_n = '0')then
--		busy <= '1';
--		ss_n <= (others => '1');
--		MOSI <= 'Z';
--		Rx_data <= (OTHERS => '0');
--	else
--	   for k in 0 to d_width-1 loop
--		if Tx_data(k) /= '0' then
--			nul := FALSE;
--			-- ??? <=> break;  
--		end if;
--	   end loop;
--	   if(nul = TRUE) then
--	   --if(Tx_data /= (others=>'0')) then
--		if(enable = '1' and clock'event and clock= '1') then
--			if(timeClk = 0 )then  --On the first rising edge of clock
--				address <= addr;
--				data <= Tx_data;
--				timeClk := timeClk +1;
--			end if;
--		end if;
--		if(timeClk = 1 and clock'event and clock= '1') then -- On the following clock
--			timeClk := 0;
--			busy <= '1';
--			for i in 0 to d_width -1 loop
--				WAIT UNTIL rising_edge (SCLK);
--				MOSI <= data(i);
--			        data(i) <= MISO;
--			end loop;
--		end if;
--		Rx_data <= data;
--		busy <= '0';
--	    end if;
--	end if;
--end process;
--

end Arch_SPI_Master;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity uart_top is
    Port ( start, clk : in STD_LOGIC;
           tx : out STD_LOGIC);
end uart_top;

architecture Behavioral of uart_top is
--9600 baud rate
--100 Mhz clock freq which gives: 100000000/9600 = 10416
---------Signals for baud rate--------
signal count : integer range 0 to 10416 := 0;
signal flag : std_logic := '0';

------Signals for data tx---------
type state_type is (rdy, send_data, check_bit);
signal state : state_type := rdy;
signal txdata : std_logic_vector(9 downto 0);
signal tx_temp : std_logic;
signal bit_count : integer range 0 to 11 := 0;

begin
BAUD_RATE_GENERATION_PROCESS: process(clk)
begin
    if(rising_edge(clk)) then
        if(state = rdy) then
            count <= 0;
        elsif(count < 10416) then  --wait till the baud rate completes to transmit the data
            count <= count + 1;
            flag <= '0';
        else
            flag <= '1';
        end if;
    end if;
end process;

DATA_TRANSMISSION_PROCESS: process(clk)
begin
    if(rising_edge(clk)) then
        case(state) is
            when rdy =>  --ready state of your ASM
                tx_temp <= '1';
                if(start = '0') then
                    state <= rdy;
                else
                    state <= send_data;
                    txdata <= ('1' & X"41" & '0');  --sending "A" on UART
                end if;
            when send_data =>
                tx_temp <= txdata(bit_count);
                bit_count <= bit_count + 1;
                state <= check_bit;
            when check_bit =>
                if(flag = '1') then
                    if(bit_count < 10) then
                        state <= send_data;
                    else
                        state <= rdy;
                        bit_count <= 0;
                    end if;
                else
                    state <= check_bit;
                end if;
            when others => state <= rdy;
        end case;
    end if;
end process;

tx <= tx_temp;

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_test is
    port (
        clk : in STD_LOGIC;             -- Clock
        rst : in STD_LOGIC;             -- Asynchronous reset
        uart_tx : out STD_LOGIC         -- UART TX output
    );
end uart_test;

architecture Behavioral of uart_test is

    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');   -- Data to transmit
    signal tx_state : std_logic := '0';                                 -- Transmission state
    signal tx_counter : integer := 0;                                   -- Bit counter

begin

    -- UART transmission process
    process (clk, rst)
    begin
        if rst = '1' then
            tx_state <= '0';
            tx_counter <= 0;
        elsif rising_edge(clk) then
            case tx_state is
                when '0' =>   -- Waiting state
                    if tx_data = "00000000" then
                        tx_state <= '0';
                    else
                        tx_state <= '1';    -- Move to transmission state
                        tx_counter <= 0;
                        uart_tx <= '0';     -- Transmit a start bit
                    end if;
                when '1' =>   -- Transmission state
                    if tx_counter < 8 then
                        uart_tx <= tx_data(tx_counter);    -- Transmit a data bit
                        tx_counter <= tx_counter + 1;
                    else
                        uart_tx <= '1';     -- Transmit a stop bit
                        tx_state <= '0';    -- Back to waiting state
                        tx_counter <= 0;
                        tx_data <= (others => '0');      -- Reset data to transmit
                    end if;
            end case;
        end if;
    end process;

    -- Data generation process to be transmitted
    process (clk, rst)
    begin
        if rst = '1' then
            tx_data <= (others => '0');
        elsif rising_edge(clk) then
            -- Example: send a fixed value of 0x5A
            tx_data <= "01011010";
        end if;
    end process;

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.numeric_std_unsigned.all;

entity send_data is
    Port (
        clk       : in  std_logic;
        button    : in  std_logic;
        uart_tx   : out std_logic;
        uart_rtsn : out std_logic
    );
end send_data;

architecture Behavioral of send_data is

    signal tx_data  : std_logic_vector(7 downto 0);
    signal tx_busy  : std_logic;
    signal tx_start : std_logic;
    signal cnt      : integer range 0 to 20000000 := 0;
    
begin

    uart_tx <= '1' when not tx_busy and tx_start = '1' else '0';

    uart_rtsn <= '1';

    process(clk)
    begin
        if rising_edge(clk) then
            
            -- Increment counter to debounce button
            if button = '0' then
                cnt <= cnt + 1;
            else
                cnt <= 0;
            end if;
            
            -- Check for button press and start sending data
            if cnt = 10000 then
                tx_data  <= "10101010"; -- Replace with your 8-bit data
                tx_busy  <= '1';
                tx_start <= '1';
            end if;
            
            -- Send data over UART
            if tx_start = '1' and not tx_busy then
                if tx_data /= "" then
                    uart_rtsn <= '0';
                    tx_busy   <= '1';
                    cnt       <= 0;
                else
                    tx_start  <= '0';
                end if;
            end if;
            
            -- Wait for UART to finish sending data
            if tx_busy = '1' then
                if cnt < 5000 then
                    cnt <= cnt + 1;
                else
                    tx_busy <= '0';
                    tx_data <= "";
                end if;
            end if;
            
        end if;
    end process;
    
end Behavioral;

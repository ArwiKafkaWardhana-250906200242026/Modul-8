----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/19/2026 03:25:44 PM
-- Design Name: 
-- Module Name: i2c_master - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2c_master is
    Generic (
        CLK_FREQ : integer := 100_000_000; -- Clock internal Basys 3 (100 MHz)
        I2C_FREQ : integer := 100_000      -- Standar I2C SCL (100 kHz)
    );
    Port (
        clk      : in    STD_LOGIC;
        reset    : in    STD_LOGIC;
        start_en : in    STD_LOGIC;
        addr     : in    STD_LOGIC_VECTOR(7 downto 0); -- 7-bit addr + 1-bit R/W
        data_in  : in    STD_LOGIC_VECTOR(7 downto 0);
        sda      : inout STD_LOGIC;                    -- inout untuk pin dua arah (open-drain)
        scl      : out   STD_LOGIC
    );
end i2c_master;

architecture Behavioral of i2c_master is
    -- Pembagi clock: (100MHz / 100kHz) / 2 = 500
    constant DIVIDER : integer := (CLK_FREQ / I2C_FREQ) / 2;
    signal clk_cnt   : integer range 0 to DIVIDER := 0;
    signal i2c_clk   : std_logic := '0';

    -- FSM States sesuai Kode 8.2
    type i2c_state is (S_IDLE, S_START, S_ADDR, S_ADDR_ACK, S_DATA, S_DATA_ACK, S_STOP);
    signal state : i2c_state := S_IDLE;
    
    signal bit_cnt : integer range 0 to 7 := 7;
    signal sda_out : std_logic := '1';
    signal sda_en  : std_logic := '0'; -- '1' jika master mengendalikan SDA, '0' jika 'Z'

begin
    -- Kendali tri-state untuk pin SDA (Z saat membaca ACK dari slave)
    sda <= sda_out when sda_en = '1' else 'Z';
    scl <= i2c_clk;

    -- Proses Clock Divider (100 MHz -> 100 kHz)
    clk_divider_proc: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                clk_cnt <= 0;
                i2c_clk <= '0';
            else
                if clk_cnt = DIVIDER - 1 then
                    clk_cnt <= 0;
                    i2c_clk <= not i2c_clk;
                else
                    clk_cnt <= clk_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- Proses FSM I2C Master
    fsm_proc: process(i2c_clk, reset)
    begin
        if reset = '1' then
            state <= S_IDLE;
            sda_out <= '1';
            sda_en <= '1';
            bit_cnt <= 7;
        elsif falling_edge(i2c_clk) then 
            case state is
                when S_IDLE =>
                    sda_out <= '1';
                    sda_en <= '1';
                    if start_en = '1' then
                        state <= S_START;
                    end if;
                    
                when S_START =>
                    sda_out <= '0'; -- START condition
                    state <= S_ADDR;
                    bit_cnt <= 7;
                    
                when S_ADDR =>
                    sda_out <= addr(bit_cnt);
                    sda_en <= '1';
                    if bit_cnt = 0 then
                        state <= S_ADDR_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                    end if;
                    
                when S_ADDR_ACK =>
                    sda_en <= '0'; -- 'Z' state untuk membaca ACK
                    state <= S_DATA;
                    bit_cnt <= 7;
                    
                when S_DATA =>
                    sda_out <= data_in(bit_cnt);
                    sda_en <= '1';
                    if bit_cnt = 0 then
                        state <= S_DATA_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                    end if;
                    
                when S_DATA_ACK =>
                    sda_en <= '0'; -- 'Z' state untuk membaca ACK
                    state <= S_STOP;
                    
                when S_STOP =>
                    sda_en <= '1';
                    sda_out <= '0'; -- Persiapan STOP
                    state <= S_IDLE;
                    
                when others =>
                    state <= S_IDLE;
            end case;
        end if;
    end process;
end Behavioral;

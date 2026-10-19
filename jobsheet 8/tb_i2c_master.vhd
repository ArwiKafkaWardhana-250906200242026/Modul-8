----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/19/2026 03:29:17 PM
-- Design Name: 
-- Module Name: tb_i2c_master - Behavioral
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

entity tb_i2c_master is
end tb_i2c_master;

architecture behavior of tb_i2c_master is
    component i2c_master
    Port (
        clk      : in    STD_LOGIC;
        reset    : in    STD_LOGIC;
        start_en : in    STD_LOGIC;
        addr     : in    STD_LOGIC_VECTOR(7 downto 0);
        data_in  : in    STD_LOGIC_VECTOR(7 downto 0);
        sda      : inout STD_LOGIC;
        scl      : out   STD_LOGIC
    );
    end component;

    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';
    signal start_en : std_logic := '0';
    signal addr     : std_logic_vector(7 downto 0) := (others => '0');
    signal data_in  : std_logic_vector(7 downto 0) := (others => '0');
    signal sda      : std_logic;
    signal scl      : std_logic;

    constant clk_period : time := 10 ns; -- Clock Basys 3 (100 MHz)
begin
    -- Instansiasi I2C Master
    uut: i2c_master PORT MAP (
        clk => clk,
        reset => reset,
        start_en => start_en,
        addr => addr,
        data_in => data_in,
        sda => sda,
        scl => scl
    );

    -- Proses Clock internal FPGA
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Proses Stimulus Testbench
    stim_proc: process
    begin
        -- Tahan reset selama 100 ns
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;
        
        -- Siapkan alamat (misal: "1010101" + bit R/W '0' = x"AA")
        addr <= x"AA"; 
        -- Siapkan data (misal: x"C3")
        data_in <= x"C3"; 
        
        -- Berikan sinyal START (mulai transaksi)
        start_en <= '1';
        wait for 20 us; -- Tunggu sedikit agar FSM mendeteksi START
        start_en <= '0';
        
        -- Biarkan simulasi berjalan cukup lama (ratusan us) 
        -- agar seluruh frame I2C (START -> ADDR -> DATA -> STOP) selesai diproses
        wait for 300 us; 
        
        wait;
    end process;
end behavior;

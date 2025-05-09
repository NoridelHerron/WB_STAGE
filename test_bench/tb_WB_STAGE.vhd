----------------------------------------------------------------------------------
--  Author      : Noridel Herron
--  Description : Testbench for WB_STAGE using uniform-based randomization.
--                Tests 5000 randomized pass-through checks.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.all;
use IEEE.MATH_REAL.ALL;

library work;
-- Customized function
use work.reusable_function.all;

entity tb_WB_STAGE is
end tb_WB_STAGE;

architecture sim of tb_WB_STAGE is

    component WB_STAGE
        Port (  -- input coming from mem stage
                data_in       : in  std_logic_vector(31 downto 0);     -- Final result from MEM_STAGE
                rd_in         : in  std_logic_vector(4 downto 0);      -- Destination register
                reg_write_in  : in  std_logic;                         -- Write enable signal from MEM_STAGE
        
                -- output will be send to decoder
                data_out      : out std_logic_vector(31 downto 0);     -- Data to write to register file
                rd_out        : out std_logic_vector(4 downto 0);      -- Register index
                reg_write_out : out std_logic  );                         -- Write enable (pass-through)
    end component;

    -- Signals (Put corresponding in-out for debugging purpose)
    signal data_in       : std_logic_vector(31 downto 0) := (others => '0'); 
    signal data_out      : std_logic_vector(31 downto 0) := (others => '0');
    signal rd_in         : std_logic_vector(4 downto 0)  := (others => '0');
    signal rd_out        : std_logic_vector(4 downto 0)  := (others => '0');
    signal reg_write_in  : std_logic := '0';
    signal reg_write_out : std_logic:= '0';

begin

    -- Module under test
    uut: WB_STAGE port map ( data_in, rd_in, reg_write_in,
         data_out, rd_out, reg_write_out );

    stimulus : process
        -- for generating value
        variable seed1, seed2 : positive := 42;
        variable rand_real    : real;
        variable rand_data    : std_logic_vector(31 downto 0);
        variable rand_rd      : std_logic_vector(4 downto 0);
        variable rand_wr      : std_logic;
        
        -- number of test
        constant NUM_TESTS    : integer := 5000;
        
        --Keep track pass/fail for debugging purpose
        variable passed, failed : integer := 0;
    begin
        wait for 10 ns;

        for i in 0 to NUM_TESTS - 1 loop
            -- Generate random 32-bit data
            for b in 0 to 31 loop
                uniform(seed1, seed2, rand_real);
                if rand_real > 0.5 then
                    rand_data(b) := '1';
                else
                    rand_data(b) := '0';
                end if;
                
            end loop;

            -- Generate random 5-bit rd
            uniform(seed1, seed2, rand_real);
            rand_rd := std_logic_vector(to_unsigned(integer(rand_real * 32.0), 5));

            -- Random reg_write
            uniform(seed1, seed2, rand_real);
            if rand_real > 0.5 then
                    rand_wr := '1';
                else
                    rand_wr := '0';
                end if;

            -- Apply inputs 
            data_in      <= rand_data;
            rd_in        <= rand_rd;
            reg_write_in <= rand_wr;

            wait for 5 ns;

            -- Check pass-through
            if data_out = rand_data and rd_out = rand_rd and reg_write_out = rand_wr then
                passed := passed + 1;
            else
                report "FAILED at test #" & integer'image(i)
                    & " | data_out = " & to_hexstring(data_out)
                    & ", expected = " & to_hexstring(rand_data)
                    & " | rd_out = " & integer'image(to_integer(unsigned(rd_out)))
                    & ", expected = " & integer'image(to_integer(unsigned(rand_rd)))
                    & " | reg_write_out = " & std_logic'image(reg_write_out)
                    & ", expected = " & std_logic'image(rand_wr)
                    severity error;
                failed := failed + 1;
            end if;

            wait for 5 ns;
        end loop;

        report "WB_STAGE TEST COMPLETE: " & integer'image(passed) & " passed, " & integer'image(failed) & " failed";
        std.env.stop;
    end process;

    watchdog : process
    begin
        wait for 300000 ns;
        report "TIMEOUT ERROR: Testbench ran too long" severity failure;
    end process;

end sim;

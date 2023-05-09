-- Copyright 2022 by Howard University All rights reserved.
--
-- Manual Testbench for: MAR
-- Design: Digital Systems (212/218/408/418)
-- Name: Goodness Atanda
--	
-- Date: 03/02/2022
--
-- Description: This the testbench for a 16 bit MAR with 9  bits output and a synchronous reset controls
-- For Lab #5
-- Digital Design Lab/Lecture (406/409)
--------------------------------------------------------------


LIBRARY IEEE;
--USE work.CLOCKS.all;   -- Entity that uses CLOCKS
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_textio.all;
USE std.textio.all;
--USE work.txt_util.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

ENTITY tb_FPA IS
END;

ARCHITECTURE TESTBENCH OF tb_FPA IS


---------------------------------------------------------------
-- COMPONENTS
---------------------------------------------------------------

component FPA
	port(clk: in std_logic;
		 rst: in std_logic;
		 OP_A: in std_logic_vector(31 downto 0);
		 OP_B: in std_logic_vector(31 downto 0);
		 OP_Q: out std_logic_vector(31 downto 0)
	     );
		 
	end component;

--COMPONENT CLOCK
--	port(CLK: out std_logic);
--END COMPONENT;

---------------------------------------------------------------
-- Read/Write FILES
---------------------------------------------------------------


FILE in_file : TEXT open read_mode is 	"input.txt";   -- Inputs, reset, enr,enl
FILE exo_file : TEXT open read_mode is 	"expected_output.txt";   -- Expected output (binary)
--FILE out_file : TEXT open  write_mode is  "dataout_dacus.txt";
--FILE xout_file : TEXT open  write_mode is "TestOut_dacus.txt";
--FILE hex_out_file : TEXT open  write_mode is "hex_out_dacus.txt";

---------------------------------------------------------------
-- SIGNALS 
---------------------------------------------------------------
	
  SIGNAL rst: STD_LOGIC :=  'X';
  SIGNAL OP_A, OP_B, OP_Q, Exp_OP_Q: STD_LOGIC_VECTOR(31 downto 0) :=  "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
  SIGNAL CLK: STD_LOGIC;
  SIGNAL Test_Out_Q : STD_LOGIC:= 'X';
  SIGNAL LineNumber: integer:=0;
  constant clock_period: time := 2 ns;

---------------------------------------------------------------
-- BEGIN 
---------------------------------------------------------------

BEGIN

---------------------------------------------------------------
-- CLOCK PROCESS
---------------------------------------------------------------
	Clock_Process: process
	begin
		Clk <= '1';
		wait for clock_period/2;
		Clk <= '0';
		wait for clock_period/2;
	end process;

---------------------------------------------------------------
-- Instantiate Components 
---------------------------------------------------------------


--U0: CLOCK port map (CLK);
--InstFPA: FPA port map (CLK, rst, OP_A, OP_B, OP_Q);

---------------------------------------------------------------
-- PROCESS 
---------------------------------------------------------------
PROCESS

variable in_line, exo_line, out_line, xout_line : LINE;
--variable comment, xcomment : string(1 to 128);
--variable i : integer range 1 to 128;
variable simcomplete : boolean;

variable vrst : std_logic := 'X';
variable vOP_A, vOP_B, vOP_Q, vEXP_OP_Q : std_logic_vector(31 downto 0) := "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
variable vTest_Out_Q : std_logic := '0';
variable vlinenumber: integer;

BEGIN

simcomplete := false;

while (not simcomplete) LOOP
  
	--if (not endfile(in_file) ) then
		readline(in_file, in_line);
	--else
		--simcomplete := true;
	--end if;

	--if (not endfile(exo_file) ) then
		readline(exo_file, exo_line);
	--else
		--simcomplete := true;
	--end if;
	
	--if (in_line(1) = '-') then  --Skip comments
		--next;
	if (in_line(1) = '.')  then  --exit Loop
	  	Test_Out_Q <= 'Z';
		simcomplete := true;
	--elsif (in_line(1) = '#') then        --Echo comments to out.txt
	  --i := 1;
	  --while in_line(i) /= '.' LOOP
		--comment(i) := in_line(i);
		--i := i + 1;
	  --end LOOP;

	--elsif (exo_line(1) = '-') then  --Skip comments
		--next;
	elsif (exo_line(1) = '.')  then  --exit Loop
	  	  Test_Out_Q  <= 'Z';
		   simcomplete := true;
	--elsif (exo_line(1) = '#') then        --Echo comments to out.txt
	     --i := 1;
	   --while exo_line(i) /= '.' LOOP
		 --xcomment(i) := exo_line(i);
		 --i := i + 1;
	   --end LOOP;

	
	  --write(out_line, comment);
	  --writeline(out_file, out_line);
	  
	  --write(xout_line, xcomment);
	  --writeline(xout_file, xout_line);

	  
	ELSE      --Begin processing

		

		read(in_line, vrst);
		rst  <= vrst;
		read(in_line, vOp_A);
		Op_A  <= vOp_A;
		--report "vOP_A : " & integer'image(to_integer(unsigned(vOP_A)));
		--report "OP_A : " & integer'image(to_integer(unsigned(OP_A)));
		read(in_line, vOp_B);
		Op_B  <= vOp_B;

		read(exo_line, vexp_Op_Q );
		--read(exo_line, vTest_Out_Q );
		
    --vlinenumber := LineNumber;
    
    --write(out_line, vlinenumber);
    --write(out_line, STRING'("."));
    --write(out_line, STRING'("    "));

	

    wait for 2 ns;
    
    Exp_Op_Q      <= vexp_Op_Q;
    
      
    if (Exp_Op_Q <= OP_Q+"101" and Exp_OP_Q >= OP_Q-"101")  then
      Test_Out_Q <= '1';
    else
      Test_Out_Q <= 'X';
    end if;
	
		vOp_Q 	:= Op_Q;
		vTest_Out_Q:= Test_Out_Q;
          		
		--write(out_line, vOp_Q, left, 32);
		--write(out_line, STRING'("       "));                           --ht is ascii for horizontal tab
		--write(out_line,vTest_Out_Q, left, 5);                           --ht is ascii for horizontal tab
		--write(out_line, STRING'("       "));                           --ht is ascii for horizontal tab
		--write(out_line, vexp_Op_Q, left, 32);
		--write(out_line, STRING'("       "));                           --ht is ascii for horizontal tab
		--writeline(out_file, out_line);
		--print(xout_file,    str(LineNumber)& "." & "    " &    str(Op_Q) & "          " &   str(Exp_Op_Q)  & "          " & str(Test_Out_Q) );

	END IF;
	LineNumber<= LineNumber+1;

	END LOOP;
	WAIT;
	
	END PROCESS;
InstFPA: FPA port map (CLK, rst, OP_A, OP_B, OP_Q);

END TESTBENCH;


CONFIGURATION cfg_tb_FPA OF tb_FPA IS
	FOR TESTBENCH
		FOR InstFPA: FPA
			use entity work.FPA(str);
		END FOR;
	END FOR;
END;	

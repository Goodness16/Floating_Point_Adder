----------------------------------------------------------------------------
-- 2 TO 1 MUX

-- A simple generic 2-to-1 mux
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
entity MUX2 is
	generic(bus_width : integer := 8);
	port(
		OP_A, OP_B: in std_logic_vector(bus_width-1 downto 0);
		Sel: in std_logic;
		OP_Q: out std_logic_vector(bus_width-1 downto 0)
	);
end MUX2;

architecture bev of MUX2 is 
begin
	OP_Q <= OP_A when (Sel = '0') else
		OP_B;
end bev;


----------------------------------------------------------------------------
-- SMALL ALU

-- A simple 8-bit ALU with just a subtractor. OP_Q is 9-bits to allow for sign bit
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity SMALL_ALU is
	port(
		OP_A, OP_B: in std_logic_vector(7 downto 0);
		OP_Q: out std_logic_vector(8 downto 0)
		);
	end SMALL_ALU;
	
architecture bev of SMALL_ALU is
begin
	OP_Q <= std_logic_vector(to_signed(to_integer(unsigned(OP_A)) - to_integer(unsigned(OP_B)),9));
end bev;


----------------------------------------------------------------------------
-- BIG ALU

-- An ALU for adding a 278-bit and 25-bit number and return a 279-bit number because of the carry bit
----------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity BIG_ALU is
	port(OP_A: in std_logic_vector(277 downto 0);
		 OP_B: in std_logic_vector(24 downto 0);
		 OP_Q: out std_logic_vector(278 downto 0)
		 );
		 
	end BIG_ALU;

architecture bev of BIG_ALU is
	signal int_sOP_Q: std_logic_vector(277 downto 0);
	signal zeros: std_logic_vector(252 downto 0) := (OTHERS =>'0'); -- 253 zeros, to make  OP_B the same length as OP_A
	signal sOP_A: std_logic_vector(278 downto 0);
	signal sOP_B: std_logic_vector(278 downto 0);
	signal sOP_Q: std_logic_vector(278 downto 0);
	
	begin
		sOP_A <= (OP_A(277) & '0' & OP_A(276 downto 0)); -- add a zero for carry bit
		sOP_B <= (OP_B(24) & '0' & OP_B(23 downto 0) & zeros); -- add a zero for carry bit
		process
		begin
			if (sOP_A(278)=sOP_B(278)) then		-- if sign bits are equal add as usual and take the sign of anyone
				int_sOP_Q <= sOP_A(277 downto 0) + sOP_B(277 downto 0);
				sOP_Q <= sOP_A(278) & int_sOP_Q;
			elsif (sOP_A(277 downto 0) < sOP_B(277 downto 0)) then	-- if sign bits are different subtract and take the sign of the higher signal
				int_sOP_Q <= sOP_B(277 downto 0) - sOP_A(277 downto 0);
				sOP_Q <= sop_B(278) & int_sOP_Q;
			elsif (sOP_A(277 downto 0) > sOP_B(277 downto 0)) then
				int_sOP_Q <= sOP_A(277 downto 0) - sOP_B(277 downto 0);
				sOP_Q <= sOP_A(278) & int_sOP_Q;
			else
				int_sOP_Q <= sOP_A(277 downto 0) - sOP_B(277 downto 0);
				sOP_Q <= '0' & int_sOP_Q;
			end if;
		WAIT on sOP_A, sOP_B, int_sOP_Q;
		end process;
	OP_Q <= sOP_Q;
	end bev;
	
	

----------------------------------------------------------------------------
-- CONTROL

-- control unit for 3 muxes and shifter
-- if the sign bit is 1 (negative), mux1 selects 0, mux2 selects 1, exp mux selects 0 and the shift_ctrl is op_a
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CONTROL is
	port(OP_A: in std_logic_vector(8 downto 0);
		 EXP_MUX_Sel, SIG_MUX_1_Sel, SIG_MUX_2_Sel: out std_logic;
		 SHIFT_CTRL: out integer 
		 );
	end CONTROL;
	
architecture bev of CONTROL is
	signal sEXP_MUX_Sel, sSIG_MUX_1_Sel, sSIG_MUX_2_Sel: std_logic;
	signal sshift_ctrl: integer;
	
	begin		 
		with OP_A(8) select
			sSig_MUX_1_Sel <= '1' when '0',
					  '0' when others;
		with OP_A(8) select
			sSIG_MUX_2_Sel <= '0' when '0',
					  '1' when others;
		with OP_A(8) select
			sEXP_MUX_Sel <=   '0' when '0',
					  '1' when others;
		with OP_A(8) select
			sshift_ctrl <= to_integer(signed(OP_A)) when '0', 
				      0-to_integer(signed(OP_A)) when others;	-- if op_a is negative the shift ctrl should be the positive complement
			
		EXP_MUX_Sel <= sEXP_MUX_Sel;
		SIG_MUX_1_Sel <= sSIG_MUX_1_Sel;
		SIG_MUX_2_Sel <= sSIG_MUX_2_Sel;
		shift_ctrl <= sshift_ctrl;
	end bev;
	
----------------------------------------------------------------------------
-- REGISTER

-- simple rising edge-level generic register
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity LREGISTER is
	generic(bus_width : integer := 32 );
	port(clk: in std_logic;
	     rst: in std_logic;
	     OP_A: in std_logic_vector(bus_width-1 downto 0);
	     OP_Q: out std_logic_vector(bus_width-1 downto 0)
	     );
	end LREGISTER;
	
architecture bev of LREGISTER is
	SIGNAL sOP_Q : std_logic_vector (bus_width-1 downto 0);
begin	
	PETFF_CLK: PROCESS(clk)
	begin
		if (clk = '1' and clk'event) then
			if (rst = '1') then
				sOP_Q <= (OTHERS => '0');
			else
				sOP_Q <= OP_A;
			end if;
		else 
			sOP_Q <= sOP_Q;
		end if;

	end process petff_clk;
	OP_Q <= sOP_Q;
END bev;		 


----------------------------------------------------------------------------
-- SHIFTER

-- 25 bit right shifter with 278 bit output to allow for a shift ctrl as large as 253
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SHIFTER is 
	port(OP_A: in std_logic_vector(24 downto 0);
		 OP_B: in integer;
		 OP_Q: out std_logic_vector(277 downto 0)
		 );
		 
	end shifter;
	
architecture bev of shifter is
	signal zeros: std_logic_vector(252 downto 0) := (OTHERS=>'0');
	signal sOP_A: std_logic_vector(277 downto 0);
	signal sOP_Q: unsigned(276 downto 0);
begin
	sOP_A <= OP_A & zeros;
	sOP_Q <= shift_right(unsigned(sOP_A(276 downto 0)), OP_B);
	OP_Q <= sOP_A(277) & std_logic_vector(sOP_Q);
end bev;

----------------------------------------------------------------------------
-- NORMALIZE HARDWARE

-- normalizing the final result: details in code belowe
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity NORMALIZE is
	port(OP_A: in std_logic_vector(277 downto 0);	-- unnormalized mantissa
		 OP_B: in std_logic_vector(7 downto 0);		-- unnormalized exponent
		 OP_Qa: out std_logic_vector(277 downto 0);	-- normalized mantissa
		 OP_Qb: out std_logic_vector(7 downto 0)	-- normalized exponent
		);
	end NORMALIZE;

architecture bev of NORMALIZE is
	signal sOP_Qa: std_logic_vector(277 downto 0);
	signal sOP_Qb: std_logic_vector(7 downto 0);
	signal sOP_Qa1: std_logic_vector(277 downto 0);
	signal sOP_Qb1: std_logic_vector(7 downto 0);
	signal sMSB: std_logic;
	signal zeros: std_logic_vector(277 downto 0) := (OTHERS => '0');
	signal Xs: std_logic_vector(277 downto 0) := (OTHERS => 'X');
	signal eight_zeros: std_logic_vector(7 downto 0) := (OTHERS => '0');

begin
	sOP_Qa <= OP_A(277 downto 0);
	sOP_Qb <= OP_B(7 downto 0);
	sMSB <= OP_A(277);
	pNORMALIZE: process
	variable vOP_Qa: std_logic_vector(277 downto 0);
	variable vOP_Qb: integer;
	variable vMSB: integer := 0;
	begin
		vOP_Qa := sOP_Qa; 
		vOP_Qb := to_integer(unsigned(sOP_Qb));
		if vOP_Qa(277) = '0' then
			vMSB := 0;
		else
			vMSB := 1;
		end if;
		if (sOP_Qa = zeros or sOP_Qa = Xs) then	-- if unormalized mantissa is all zeros or Xs then leave as it is
			sOP_Qa1 <= sOP_Qa;
			sOP_Qb1 <= sOP_Qb;
		elsif (sMSB = '1') then	-- if the MSB is 1 then it is a carry bit and you just need to shift once to the right and increase exponent
			sOP_Qa1 <= sOP_Qa;
			sOP_Qb1 <= sOP_Qb + "00000001";
		else	-- while the msb is zero keeps shifting to the left and subtracting from the exponent
			while vMSB = 0 loop	
				vOP_Qa := vOP_Qa(276 downto 0) & '0';
				vOP_Qb := vOP_Qb -1;
				if vOP_Qa(277) = '0' then
					vMSB := 0;
				else
					vMSB := 1;
				end if;
			end loop;
			sOP_Qa1 <= vOP_Qa;
			sOP_Qb1 <= std_logic_vector(to_unsigned(vOP_Qb+1, sOP_Qb'length));
		end if;
	sOP_Qa1 <= vOP_Qa;
	sOP_Qb1 <= std_logic_vector(to_unsigned(vOP_Qb+1, sOP_Qb'length));
	WAIT on sOP_Qa, sOP_Qb, sOP_Qa1, sOP_Qb1;
	end process pNORMALIZE;
	OP_Qa <= sOP_Qa1;
	OP_Qb <= sOP_Qb1;
end bev;

----------------------------------------------------------------------------
-- FPA

-- the main module for the floating point adder that instantiates
-- the previously developed components and wires them
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity FPA is
	port(clk: in std_logic;
		 rst: in std_logic;
		 OP_A: in std_logic_vector(31 downto 0);
		 OP_B: in std_logic_vector(31 downto 0);
		 OP_Q: out std_logic_vector(31 downto 0)
	     );
		 
	end FPA;
	
architecture str of FPA is

-------------------------------------------------------------------------------
-- call the components created above
-------------------------------------------------------------------------------
	component mux2
		generic(bus_width : integer := 8);
		port(
			OP_A, OP_B: in std_logic_vector(bus_width-1 downto 0);
			Sel: in std_logic;
			OP_Q: out std_logic_vector(bus_width-1 downto 0)
		);
	end component;
	
	component SMALL_ALU 
		port(
			OP_A, OP_B: in std_logic_vector(7 downto 0);
			OP_Q: out std_logic_vector(8 downto 0)
			);
		end component;
		
	component BIG_ALU 
		port(OP_A: in std_logic_vector(277 downto 0);
		 	OP_B: in std_logic_vector(24 downto 0);
		 	OP_Q: out std_logic_vector(278 downto 0)
		 	);
		end component;
		
	component CONTROL
		port(OP_A: in std_logic_vector(8 downto 0);
		 	EXP_MUX_Sel, SIG_MUX_1_Sel, SIG_MUX_2_Sel: out std_logic;
			SHIFT_CTRL: out integer
		 	);
		end component;
	
	component LREGISTER
		generic(bus_width : integer := 32 );
		port(clk: in std_logic;
		 	rst: in std_logic;
		 	OP_A: in std_logic_vector(bus_width-1 downto 0);
		 	OP_Q: out std_logic_vector(bus_width-1 downto 0)
		 	);
		end component;
		
	component SHIFTER 
		port(OP_A: in std_logic_vector(24 downto 0);
		 	OP_B: in integer;
		 	OP_Q: out std_logic_vector(277 downto 0)
		 	);		 
		end component;
		
	component NORMALIZE
		port(OP_A: in std_logic_vector(277 downto 0);
		 	OP_B: in std_logic_vector(7 downto 0);
		 	OP_Qa: out std_logic_vector(277 downto 0);
		 	OP_Qb: out std_logic_vector(7 downto 0)
			);
		end component;
		
-------------------------------------------------------------------------------
-- signals
-------------------------------------------------------------------------------
	signal exp_diff   : std_logic_vector(8 downto 0);	-- the 9-bit exponent difference
	signal sexp_mux_Sel, ssig_mux_1_Sel, ssig_mux_2_Sel: std_logic;	-- control signals for 2-to-1 muxes
	signal sOP_A, sOP_B : std_logic_vector(24 downto 0); -- significand and sign bit of op_a and op_b
	signal large_exp : std_logic_vector(7 downto 0);	-- the large exponent
	signal significand1 : std_logic_vector(24 downto 0);	-- the significand of the lower input 
	signal significand2 : std_logic_vector(24 downto 0);	-- the significand of the higher input
	signal significand2_with_exponent : std_logic_vector(32 downto 0);	-- the signifciand and the large exponent
	signal one: std_logic := '1';	-- signal of one
	signal shifted_significand1 : std_logic_vector(277 downto 0);	-- the first significand after shifting
	signal stage1_opA : std_logic_vector(277 downto 0);	-- the first output after comparing exponent and
	signal stage1_opB : std_logic_vector(32 downto 0);	-- the second output after comparing 
	signal result : std_logic_vector(278 downto 0);	    -- the result of adding
	signal result1: std_logic_vector(286 downto 0);		-- the exponent and the result
	signal stage2_result: std_logic_vector(286 downto 0);	-- the output after add stage
	signal normalized: std_logic_vector(277 downto 0);	-- the normalized mantissa
	signal normalized_exp: std_logic_vector(7 downto 0);	-- the normalized exponent
	signal sOP_Q : std_logic_vector(31 downto 0);		-- final output signal
	signal sshift_ctrl: integer;					-- the shift control
	
begin
	SUB_EXP : SMALL_ALU port map(OP_A(30 downto 23), OP_B(30 downto 23), exp_diff);	-- subtract exponents and put it in exp_diff
	CONTROL_UNIT : CONTROL Port map(exp_diff, sexp_mux_Sel, ssig_mux_1_Sel, ssig_mux_2_Sel, sshift_ctrl); -- use the exp_diff to determine which input is smaller and larger
																										  -- determine which exponent is larger
																										  -- determine the shift control
	EXPONENT_MUX : MUX2 Port map(OP_A(30 downto 23), OP_B(30 downto 23), sexp_mux_Sel, large_exp); -- take the larger exponent
	sOP_A <= OP_A(31) & one & OP_A(22 downto 0);	-- take the sign bit and the significand of OP_A
	sOP_B <= OP_B(31) & one & OP_B(22 downto 0);	-- take the sign bit and the significand of OP_B
	SIGNIFICAND_MUX1 : MUX2 generic map(bus_width => 25)
			       		   Port map(sOP_A, sOP_B, ssig_mux_1_sel, significand1);	-- choose the smaller significand
	SIGNIFICAND_MUX2: MUX2 generic map(bus_width => 25) 
			       		   Port map(sOP_A, sOP_B, ssig_mux_2_sel, significand2);	-- choose the larger significand
	LSHIFT_RIGHT: SHIFTER Port map(significand1, sshift_ctrl, shifted_significand1); -- shift the smaller significand to the right using shift_ctrl
	STAGE1_REGISTER_A: LREGISTER generic map(bus_width => 278) 						 
				     			 port map(clk, rst, shifted_significand1, stage1_opA);	-- store the result from stage 1 into register
	significand2_with_exponent <= large_exp & significand2;	-- concatenate the second significand and large exponent signal for storing without using a third register
	STAGE1_REGISTER_B: LREGISTER generic map(bus_width => 33) 
				     			 port map(clk, rst, significand2_with_exponent, stage1_opB);	-- store the result from stage 1 into register
	ADD: BIG_ALU port map(stage1_opA, stage1_opB(24 downto 0), result);	 -- add the two numbers
	result1 <= stage1_opB(32 downto 25) & result;	-- concatenate the result and the exponent to store without using a second register
	STAGE2_REGISTER_RESULT: LREGISTER generic map(bus_width => 287)
					  				  port map(clk, rst, result1, stage2_result);	-- store the result from stage 2 into the register
	NORMALIZE_RESULT: NORMALIZE port map(stage2_result(277 downto 0), stage2_result(286 downto 279), normalized, normalized_exp);	-- normalize the result and exponent
	sOP_Q <= stage2_result(278) & normalized_exp & normalized(276 downto 254);	-- concatenate the sign bit exponent and significan to form a 32 bit IEEE single precision floating number
	OP_Q <= sOP_Q;	-- output the result
	
end str;								  
			   

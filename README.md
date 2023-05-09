# Floating_Point_Adder
Pipelined Floating Point Adder
	Introduction
The floating point adder is a complex module in an ALU that adds two floating point numbers. Floating points are notoriously difficult to deal with, with tons of research going into addition, multiplication, division and different arithmetic on this numbers. The representation used in most computer systems is the IEEE 756 floating point single(32-bit) and double(64-bit) precision. The single precision uses 1-bit for the sign, 8-bits for the exponent with a bias of 127, and 23-bits for the significand. 
±1.significand × 10^(exponent-127)
	When adding these floating numbers, there are 5 steps:
	Compare Exponents: Check which of the two numbers is smaller and keep the exponent of the larger number
	Shift smaller number right: To align the exponent we shift the smaller number to the right and increase the exponent once until both exponents are equal
	Add: Add or subtract depending on the sign bits.
	Normalize: Normalize the result until the MSB is 1.
	Rounding: Round the answer using any rounding hardware. Sometimes rounding and normalizing are done in any order. There is no rounding in my FPA implementation.
  

 
	The data path above is used to do these operations. The two inputs exponent is put in the small ALU to get the exponent difference. This exponent difference is the control unit and controls of the mux that chooses the larger exponent, the mux that chooses the significand of the smaller exponent to be shifted right, and the mux that chooses the significand of the larger exponent. These two significands are added and then normalized by shifting left or right and increasing or decreasing the exponent accordingly. 

	Pipeline Structure
The pipelined structure uses the same data path as the first one, the only difference being that registers are needed between stages to make sure the inputs to each stage is the right input and not the input of a previous or future process. The steps are divided into stages for the pipeline stages. There are many ways to achieve the pipeline by combining any of the steps. There are three ways to achieve a 3-stage pipeline: 
	Compare Exponents & Shift small number right -> Add -> Normalize
	Compare Exponents -> Shift small number right & Add -> Normalize
	Compare Exponents -> Shift small number right -> Add & Normalize
The third way is the least efficient because Adding and Normalizing are the slowest steps, so the clock cycle is large. The first way is slightly more efficient than the second way because Adding and shifting takes more time than comparing and shifting which is why I picked the first way to implement my pipeline. Also, it looks more “appealing” as a designer because it looks like comparing and shifting are the same process, and it helps to simplify the register hardware between stages. A four-stage pipeline is not more impressive than the first 3 stage pipeline because comparing and shifting takes a little more time than adding.
 
Two register files are used in the image above between each stage. The first one has the input and shifted input, the second register has the sum they also both contain the large exponent. 


	Code implementation
The VHDL code has been placed in GitHub with the link provided below for your convenience.
A few notes:
	I designed the components individually using behavioral modeling. I connected the components and their signals in the main FPA entity using structural modeling. 
	I decided to shift the first input to a 277-bit output to allow for a shift control as large as 254 bits for exponent inputs like 0(-127) and 254(127).
	Instead of using a different register for the large exponent in the first stage, I combined it with the signal from the second significand which in hindsight seemed to increase hardware complexity. A similar style is used after the second stage to combine the result and the large exponent. 
	The VHDL can handle the exception of adding two similar floating points with different signs to give a zero output(all zeros). However, zero cannot be an input.
	The reset is conventional and is only used on the first input to “flush” the registers.

	Testbench
I designed a testbench that can use an input and expected output file to test the VHDL code. The input and expected output file is randomly generated using a MATLAB m file. The clock cycle is 2 ns and can run for as long as the input is. The VHDL testbench, MATLAB m file, input text file and expected output text file are also included in the GitHub repo.

	Waveform
 
Above is a picture of the waveform over a few clock cycles. For simulation, we chose the clock cycle to be 2 ns and that each stage takes the same time, in synthesis this is not true and the third stage should be the critical path. The highlight shows the input and output signals(red), the output of the register from the first stage, which is also the input into the second stage(blue) and the output from the second stage which is also the input into the third stage(green). 
	You can see that a new input goes in every clock cycle while the previous input is still processing. It takes 3 clock cycles from input to output because of the 3 pipeline stages. The registers make the combinational circuit in the previous stages sequential on the rising edge of each clock. 
	You can see that the output of stage 1 from the first input is on the 2nd clock cycle, which is when a new input is taken. The output of  the first input is on the 3rd clock cycle with a new input in stage 1 and the second input in stage 2, this pipelined pattern takes place for all inputs with it taking n + 2 clock cycles where n is the number of instructions. 

	Performance analyses
The waveform above shows it takes 6 ns to get an output and we assumed that each stage took the same time. In synthesis, however, the third stage takes longer than the second stage which takes longer than the first stage. If we assume that it takes 2 ns for stage 1, 1.7 ns for stage 2, and 1 ns for stage 3 (these are all assumptions and the design has to be synthesized or designed to get the correct delay for these stages) the time will take 4.7 ns which is the clock cycle for a non-pipelined implementation. If we are executing 100 floating-point additions, this will come down to 470 ns, however with my pipelined implementation, the clock cycle is 2 ns and 100 floating-point additions will take 102 clock cycles, this will come down to 204 ns, making the speed up 2.30 which is a lot. So the pipelined version is much more efficient. Moreover, we don’t have to deal with pesky hazards like structural hazard(we have different ALU for adding significands and subtracting exponents), data hazards(no dependency), or control hazards(no branching).

	Github 

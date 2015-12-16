
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.ipbus.all;
use work.user_package.all;

entity ROC_ch_gen_v1 is
port (			clk_i 							: in   std_logic;
					sclr_i 							: in   std_logic;
					--
					start_i 							: in   std_logic;
					--
					trigger_i						: in std_logic;
					trigger_en_i					: in std_logic; --pause_trigger_i : pause/resume to wait new data set					
					--
					ch_word4b_ROC 					: out  std_logic_vector(3 downto 0 );
					--param
					--HIT_NB_ROC_MODE
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt from [0:15]; incremented for each new frame (not yet)
					--"0010" : pseudo-random (not yet)					
					hit_nb_ROC_mode_i				: in std_logic_vector(3 downto 0);
					--MATRIX_MODE [dcol-row]
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt; but if several hits/roc => same value; incremented for each new frame; common for all ROC & Hit/ROC
					--"0010" : pseudo-random (not yet)
					matrix_mode_i					: in std_logic_vector(3 downto 0); 
					--HIT_DATA_MODE
					--MATRIX_MODE [dcol-row]
					--"0000" : fixed (predefined values updated from s/w) 
					--"0001" : cnt (not yet)
					--"0010" : pseudo-random (not yet)					
					hit_data_mode_i				: in std_logic_vector(3 downto 0);
					--
					ROC_nb_i							: in std_logic_vector(3 downto 0); --[0:8] with 1<=>1	
					--hitNbByROC
					hit_nb_ROCn0_i					: in std_logic_vector(3 downto 0); --"0000" : 0 / "1111" : 15
					hit_nb_ROCn1_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn2_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn3_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn4_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn5_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn6_i					: in std_logic_vector(3 downto 0);
					hit_nb_ROCn7_i					: in std_logic_vector(3 downto 0);
					--dcol if constant => base-6 format
					dcol_ROCn0_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn1_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn2_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn3_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn4_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn5_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn6_i					: in std_logic_vector(5 downto 0);
					dcol_ROCn7_i					: in std_logic_vector(5 downto 0);					
					--row if constant => base-6 format
					row_ROCn0_i						: in std_logic_vector(8 downto 0);
					row_ROCn1_i						: in std_logic_vector(8 downto 0);
					row_ROCn2_i						: in std_logic_vector(8 downto 0);
					row_ROCn3_i						: in std_logic_vector(8 downto 0);
					row_ROCn4_i						: in std_logic_vector(8 downto 0);
					row_ROCn5_i						: in std_logic_vector(8 downto 0);
					row_ROCn6_i						: in std_logic_vector(8 downto 0);
					row_ROCn7_i						: in std_logic_vector(8 downto 0);	
					--hit if constant => base-6 format
					hit_ROCn0_i						: in std_logic_vector(7 downto 0);
					hit_ROCn1_i						: in std_logic_vector(7 downto 0);
					hit_ROCn2_i						: in std_logic_vector(7 downto 0);
					hit_ROCn3_i						: in std_logic_vector(7 downto 0);
					hit_ROCn4_i						: in std_logic_vector(7 downto 0);
					hit_ROCn5_i						: in std_logic_vector(7 downto 0);
					hit_ROCn6_i						: in std_logic_vector(7 downto 0);
					hit_ROCn7_i						: in std_logic_vector(7 downto 0);
					--
					TOKEN_ROC_IN					: in std_logic;
					TOKEN_ROC_OUT					: out std_logic
					--stack
					
		  );
end ROC_ch_gen_v1;

architecture Behavioral of ROC_ch_gen_v1 is
type t_state is ( 				idle,
										START_ROC,
										STOP_ROC,
										RH0,
										RH1,
										RH2,
										RH3,
										PXD1,
										PXD2,
										PXD3,
										PXD4,
										PXD5,
										PXD6,
										TT1
								);
	signal s_state 							: t_state;



	--signal stack								: std_logic_vector(5 downto 0) := (others=>'0');
	signal ROC_cnt 							: integer range 0 to 15 := 0; --4b
	signal ROC_index 							: integer range 0 to 7 := 0; --3b
	
	signal ROC_cnt_end 						: std_logic:='0';		
	

	type array_8x6bit 						is array (0 to 7) of std_logic_vector(5 downto 0); 
	type array_8x9bit 						is array (0 to 7) of std_logic_vector(8 downto 0); 
	type array_8x8bit 						is array (0 to 7) of std_logic_vector(7 downto 0);
	type array_8x4bit_unsigned				is array (0 to 7) of unsigned(3 downto 0);	
	type array_8x4bit							is array (0 to 7) of std_logic_vector(3 downto 0);
	
   signal dcol_ROCn 							: array_8x6bit 				:= (others => (others => '0'));
   signal row_ROCn 							: array_8x9bit 				:= (others => (others => '0'));
	signal hit_ROCn 							: array_8x8bit 				:= (others => (others => '0'));
--	signal hit_nb_ROCn 						: array_8x4bit_unsigned 	:= (others => (others => '0'));
	signal hit_nb_ROCn 						: array_8x4bit 				:= (others => (others => '0'));
	signal hit_cnt								: integer range 0 to 15		:= 0; --4b



	signal dcol_cnt							: std_logic_vector(5 downto 0) := (others => '0'); 
	signal dcol_cnt_en						: std_logic := '0'; --EN if '1' / one-pulse
	signal dcol_cnt_end						: std_logic := '0'; --active high	
	
	signal row_cnt								: std_logic_vector(8 downto 0) := (others => '0'); 
	signal row_cnt_en							: std_logic := '0'; --EN if '1' / one-pulse
	signal row_cnt_end						: std_logic := '0'; --active high	

	constant CMD0 								: std_logic_vector(hit_nb_ROC_mode_i'range) := std_logic_vector(to_unsigned(0,hit_nb_ROC_mode_i'length));
	constant CMD1 								: std_logic_vector(hit_nb_ROC_mode_i'range) := std_logic_vector(to_unsigned(1,hit_nb_ROC_mode_i'length));	
	constant CMD2 								: std_logic_vector(hit_nb_ROC_mode_i'range) := std_logic_vector(to_unsigned(2,hit_nb_ROC_mode_i'length));	

	signal read_pixelData_en				: std_logic := '0';

	constant ch_word4b_ROC_Idle			: std_logic_vector(3 downto 0) := x"F";

begin
--============--
	-- OUTPUTTING --
	--============--
	--ch_word4b_o	<= ch_word4b;

	--=================--
	-- MATRIX COUNTING --
	--=================--
	--ROW from [0:160], incremented first 
	row_counter_inst: entity work.row_counter 
	port map(
					clk_i			 		=> clk_i,
					sclr_i 				=> sclr_i,
					row_cnt_en_i 		=> row_cnt_en,
					row_cnt_o 			=> row_cnt,
					row_cnt_end_o		=> row_cnt_end					
			);

	--DCOL from [0:26], incremented when row_cnt_end active
	dcol_counter_inst: entity work.dcol_counter 
	port map(
					clk_i			 		=> clk_i,
					sclr_i 				=> sclr_i,
					dcol_cnt_en_i 		=> dcol_cnt_en,
					dcol_cnt_o 			=> dcol_cnt,
					dcol_cnt_end_o		=> dcol_cnt_end
			);


	row_cnt_en 			<= read_pixelData_en;
	dcol_cnt_en 		<= row_cnt_end and read_pixelData_en;
	
	--===================--
	-- MATRIX [dcol-row] --
	--===================--
	process
	begin
		wait until rising_edge(clk_i);
			--***************************************--		
			--with predefined constants for each ROC --
			--***************************************--			
			if 		matrix_mode_i = CMD0 then
				--dcol
				dcol_ROCn(0) 	<= dcol_ROCn0_i;
				dcol_ROCn(1) 	<= dcol_ROCn1_i;
				dcol_ROCn(2) 	<= dcol_ROCn2_i;
				dcol_ROCn(3) 	<= dcol_ROCn3_i;
				dcol_ROCn(4) 	<= dcol_ROCn4_i;
				dcol_ROCn(5) 	<= dcol_ROCn5_i;
				dcol_ROCn(6) 	<= dcol_ROCn6_i;	
				dcol_ROCn(7) 	<= dcol_ROCn7_i;
				--row
				row_ROCn(0) 	<= row_ROCn0_i;
				row_ROCn(1) 	<= row_ROCn1_i;
				row_ROCn(2) 	<= row_ROCn2_i;
				row_ROCn(3) 	<= row_ROCn3_i;
				row_ROCn(4) 	<= row_ROCn4_i;
				row_ROCn(5) 	<= row_ROCn5_i;
				row_ROCn(6) 	<= row_ROCn6_i;	
				row_ROCn(7) 	<= row_ROCn7_i;
			--***************************************--
			-- with counting data common for all ROCs -
			--***************************************--
			-- but if several hits/roc => same value; incremented for each new frame; common for all ROC & Hit/ROC
			elsif		matrix_mode_i = CMD1 and read_pixelData_en = '1' then 
				--dcol
				dcol_ROCn(0) 	<= dcol_cnt;
				dcol_ROCn(1) 	<= dcol_cnt;
				dcol_ROCn(2) 	<= dcol_cnt;
				dcol_ROCn(3) 	<= dcol_cnt;
				dcol_ROCn(4) 	<= dcol_cnt;
				dcol_ROCn(5) 	<= dcol_cnt;
				dcol_ROCn(6) 	<= dcol_cnt;	
				dcol_ROCn(7) 	<= dcol_cnt;
				--row
				row_ROCn(0) 	<= row_cnt;
				row_ROCn(1) 	<= row_cnt;
				row_ROCn(2) 	<= row_cnt;
				row_ROCn(3) 	<= row_cnt;
				row_ROCn(4) 	<= row_cnt;
				row_ROCn(5) 	<= row_cnt;
				row_ROCn(6) 	<= row_cnt;	
				row_ROCn(7) 	<= row_cnt;
			end if;
	end process;


	--==========--
	-- HIT DATA --
	--==========--
	--***************************************--		
	--with predefined constants for each ROC --
	--***************************************--
	hit_ROCn(0) 	<= hit_ROCn0_i;
	hit_ROCn(1) 	<= hit_ROCn1_i;
	hit_ROCn(2) 	<= hit_ROCn2_i;
	hit_ROCn(3) 	<= hit_ROCn3_i;
	hit_ROCn(4) 	<= hit_ROCn4_i;
	hit_ROCn(5) 	<= hit_ROCn5_i;
	hit_ROCn(6) 	<= hit_ROCn6_i;	
	hit_ROCn(7) 	<= hit_ROCn7_i;
--	process
--	begin
--		wait until rising_edge(clk_i);
--			--***************************************--		
--			--with predefined constants for each ROC --
--			--***************************************--			
--			if 		hit_data_mode_i = CMD0 then
--				hit_ROCn(0) 	<= hit_ROCn0_i;
--				hit_ROCn(1) 	<= hit_ROCn1_i;
--				hit_ROCn(2) 	<= hit_ROCn2_i;
--				hit_ROCn(3) 	<= hit_ROCn3_i;
--				hit_ROCn(4) 	<= hit_ROCn4_i;
--				hit_ROCn(5) 	<= hit_ROCn5_i;
--				hit_ROCn(6) 	<= hit_ROCn6_i;	
--				hit_ROCn(7) 	<= hit_ROCn7_i;
--			end if;
--	end process;


	--============--
	-- HIT_NB_ROC --
	--============--
	--***************************************--		
	--with predefined constants for each ROC --
	--***************************************--
	hit_nb_ROCn(0) 				<= hit_nb_ROCn0_i;
	hit_nb_ROCn(1) 				<= hit_nb_ROCn1_i;
	hit_nb_ROCn(2) 				<= hit_nb_ROCn2_i;
	hit_nb_ROCn(3) 				<= hit_nb_ROCn3_i;
	hit_nb_ROCn(4) 				<= hit_nb_ROCn4_i;
	hit_nb_ROCn(5) 				<= hit_nb_ROCn5_i;
	hit_nb_ROCn(6) 				<= hit_nb_ROCn6_i;	
	hit_nb_ROCn(7) 				<= hit_nb_ROCn7_i;
--	process
--	begin
--		wait until rising_edge(clk_i);
--			--***************************************--		
--			--with predefined constants for each ROC --
--			--***************************************--			
--			if 		hit_nb_ROC_mode_i = CMD0 then
--				hit_nb_ROCn(0) 				<= hit_nb_ROCn0_i;
--				hit_nb_ROCn(1) 				<= hit_nb_ROCn1_i;
--				hit_nb_ROCn(2) 				<= hit_nb_ROCn2_i;
--				hit_nb_ROCn(3) 				<= hit_nb_ROCn3_i;
--				hit_nb_ROCn(4) 				<= hit_nb_ROCn4_i;
--				hit_nb_ROCn(5) 				<= hit_nb_ROCn5_i;
--				hit_nb_ROCn(6) 				<= hit_nb_ROCn6_i;	
--				hit_nb_ROCn(7) 				<= hit_nb_ROCn7_i;
--			end if;
--	end process;



	--
	ROC_cnt_end <= '1' when ROC_cnt = 0 else '0';




	--=======================--
	-- FSM - Frame Generator --
	--=======================--	
	process
	begin
	wait until rising_edge(clk_i);	-- rising clock edge
		--
		if sclr_i = '1' then
			ch_word4b_ROC							<= ch_word4b_ROC_Idle; 
			--event_cnt								<= (others=>'0');
			ROC_cnt									<= 15;
			ROC_index								<= 0;			
			read_pixelData_en						<= '0';
			TOKEN_ROC_OUT							<= '0';
			s_state 									<= idle;
		else
		
			case s_state is
				
				when idle =>	--start + wait trigger			
					ch_word4b_ROC 					<= ch_word4b_ROC_Idle;
					ROC_cnt							<= to_integer(unsigned(ROC_nb_i));
					ROC_index						<= 0;
					TOKEN_ROC_OUT					<= '0';
					--hit_cnt							<= to_integer(unsigned(hit_nb_ROCn(0)));
					--
					if TOKEN_ROC_IN = '1' then
						
						if ROC_nb_i = std_logic_vector(to_unsigned(0,ROC_nb_i'length)) then
							TOKEN_ROC_OUT				<= '1';
							ch_word4b_ROC				<= ch_word4b_ROC_Idle;
							s_state						<= TT1;
						else
							read_pixelData_en			<= '1';
							s_state 						<= RH1;
						end if;					else
						
						s_state						<= idle;
					end if;
					
					
				-------------------------------------------------------------------------
				--when RH0 =>	--start + wait trigger			
			
				
				-------------------------------------------------------------------------
--				when START_ROC =>	
--					--
--					if ROC_nb_i = std_logic_vector(to_unsigned(0,ROC_nb_i'length)) then
--						TOKEN_ROC_OUT				<= '1';
--						ch_word4b_ROC				<= ch_word4b_ROC_Idle;
--						s_state						<= TT1;
--					else
--						read_pixelData_en			<= '1';
--						s_state 						<= RH1;
--					end if;
					--
				
				-------------------------------------------------------------------------
				when RH1 =>
					ROC_cnt							<= ROC_cnt - 1; --DEC
					hit_cnt							<= to_integer(unsigned(hit_nb_ROCn(ROC_index))); --mux/switch
					ch_word4b_ROC 						<= x"7"; 
					read_pixelData_en				<= '0';					
					s_state 							<= RH2;
				
				-------------------------------------------------------------------------
				when RH2 =>
					ch_word4b_ROC 						<= x"F"; 
					read_pixelData_en				<= '0';	--one-pulse				
					s_state 							<= RH3;
				
				-------------------------------------------------------------------------
				when RH3 =>
					ch_word4b_ROC 						<= "10" & "00";  --ReadBackId = "00"	
					--
					if hit_cnt = 0 then
						--
						if ROC_cnt = 0 then
							TOKEN_ROC_OUT			<= '1';
							s_state					<= TT1;
						else
							ROC_index				<= ROC_index + 1;
							s_state 					<= RH1;		
						end if;
						--
					else
						hit_cnt						<= hit_cnt - 1;
						s_state 						<= PXD1;
					end if;
					--
				
				-------------------------------------------------------------------------  
				when PXD1 =>
					ch_word4b_ROC 						<= dcol_ROCn(ROC_index)(5 downto 2);
					s_state 							<= PXD2;  
				
				-------------------------------------------------------------------------
				when PXD2 =>
					ch_word4b_ROC 						<= dcol_ROCn(ROC_index)(1 downto 0) &  row_ROCn(ROC_index)(8 downto 7); 
					s_state 							<= PXD3;  
				
				-------------------------------------------------------------------------
				when PXD3 =>
					ch_word4b_ROC 						<= row_ROCn(ROC_index)(6 downto 3);  
					s_state 							<= PXD4;  
				
				-------------------------------------------------------------------------
				when PXD4 =>
					ch_word4b_ROC 						<= row_ROCn(ROC_index)(2 downto 0) & hit_ROCn(ROC_index)(7);  
					s_state 							<= PXD5;  
				
				----------------------------------------------------------------------
				when PXD5 =>
					ch_word4b_ROC 						<= hit_ROCn(ROC_index)(6 downto 4) & '0';  
					s_state 							<= PXD6;  
				
				----------------------------------------------------------------------
				when PXD6 =>
					ch_word4b_ROC 						<= hit_ROCn(ROC_index)(3 downto 0);
					--
					if hit_cnt = 0 then
						--
						if ROC_cnt = 0 then
							TOKEN_ROC_OUT			<= '1';
							s_state					<= TT1;
						else
							ROC_index				<= ROC_index + 1;
							s_state 					<= RH1;		
						end if;
						--
					else
						hit_cnt						<= hit_cnt - 1;
						s_state 						<= PXD1;
					end if;
					--
				--------------------------------------------------------------------------
				when TT1 =>
					ch_word4b_ROC					<= ch_word4b_ROC_Idle; 
					TOKEN_ROC_OUT					<= '0';
					s_state							<= idle;
				when others => 
					null;
					
				
			end case;
		end if;
end process;



end Behavioral;


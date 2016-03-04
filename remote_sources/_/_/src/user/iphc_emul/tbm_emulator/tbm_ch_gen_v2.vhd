----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:09:22 01/09/2015 
-- Design Name: 
-- Module Name:    tbm_ch_gen_v1 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tbm_ch_gen_v2 is
generic (
					loop_bit_size					: positive := 16;
					wait_bit_size					: positive := 28;
					mem_addr_width					: positive := 16
			);
					
					
port (			clk_i 							: in std_logic;
					sclr_i 							: in std_logic;
					--
					start_i 							: in std_logic;
					--
					trigger_i						: in std_logic;
					trigger_mode_i					: in std_logic;					
					--mem
					mem_cs_o							: out std_logic;
					mem_rd_en_o   					: out std_logic;
					mem_addr_o						: out std_logic_vector(mem_addr_width-1 downto 0);
					mem_data_i						: in std_logic_vector(31 downto 0);
					--
					ch_word4b_o 					: out std_logic_vector(3 downto 0);	
					--param
					loop_nb_i						: in std_logic_vector(loop_bit_size-1 downto 0)		
					
		  );
end tbm_ch_gen_v2;

architecture Behavioral of tbm_ch_gen_v2 is

	
	type state_type 							is ( 		s0, s0_bis, s1, s2, s3, s4, s_wait, s_loop, s_end);
	signal state 								: state_type;
  
	constant ch_word4b_Idle					: std_logic_vector(3 downto 0) := x"F"; 
	signal ch_word4b							: std_logic_vector(3 downto 0) := ch_word4b_Idle;

	
	signal mem_addr 							: integer range 0 to 2**mem_addr_width-1 := 0;
	signal mem_rd_en							: std_logic := '0';	
	signal mem_cs								: std_logic := '0';	
	
	signal word_data_current				: std_logic_vector(31 downto 0) := (others=>'0');
	signal word_data_next					: std_logic_vector(31 downto 0) := (others=>'0');

	signal q_cnt 								: integer range 0 to 7 := 7;
	signal q_cnt2 								: integer range 0 to 7 := 7;
	
	signal wait_cnt 							: integer range 0 to 2**wait_bit_size-1 := 0;
	signal loop_cnt 							: integer range 0 to 2**loop_bit_size-1 := 0;
	
	signal wait_detect_from_s2				: std_logic := '0';
	signal wait_detect_from_s3				: std_logic := '0';	
	
begin



	--I/O
	ch_word4b_o					<= ch_word4b;

	mem_rd_en_o 				<= mem_rd_en;
	mem_addr_o					<= std_logic_vector(to_unsigned(mem_addr,mem_addr_width));
	mem_cs_o						<= mem_cs;

	process
	begin
	wait until rising_edge(clk_i);	-- rising clock edge
		--
		if sclr_i = '1' then
			ch_word4b 									<= ch_word4b_Idle; 
			mem_rd_en 									<= '0';
			mem_cs										<= '0';
			mem_addr										<= 0;			
			q_cnt											<= 7;
			q_cnt2										<= 7;			
			wait_cnt										<= 0;
			loop_cnt										<= 0;
			--
			wait_detect_from_s2						<= '0';		
			wait_detect_from_s3						<= '0';				
			state 										<= s0;
		else
		--
			--
			case state is
				--
				when s0 =>
					mem_addr								<= 0;
					loop_cnt 							<= to_integer(unsigned(loop_nb_i));
					wait_detect_from_s2				<= '0';		
					wait_detect_from_s3				<= '0';						
					--
					if start_i = '1' then 
						mem_cs							<= '1';						
						state 							<= s0_bis;
					else
						mem_cs							<= '0';					
						mem_rd_en 						<= '0';
						ch_word4b	 					<= ch_word4b_Idle;
					end if;


				--
				when s0_bis => --TRIG or WAIT MODE 
					if ( (trigger_i = '1' and trigger_mode_i = '1') or trigger_mode_i = '0' )  then 
						mem_rd_en 						<= '1';
						mem_cs							<= '1';						
						state 							<= s1;
					else
						mem_rd_en 						<= '0';						
					end if;

				--
				when s1 =>
					mem_addr								<= mem_addr + 1;
					--word_data_current 				<= mem_data_i;
					state									<= s2;

				--
				when s2 =>	
					mem_rd_en 							<= '0';
					--mem_addr								<= mem_addr + 1; --the next 
					--
					if mem_data_i(31 downto 28) = "1111" then
						q_cnt								<= 7;--bidon
						ch_word4b 						<= ch_word4b_Idle;
						mem_addr							<= 0;							
						state								<= s_loop; 
					elsif mem_data_i(31 downto 28) = "1000" then
						q_cnt								<= 7;--bidon			
						ch_word4b 						<= ch_word4b_Idle;
						wait_cnt							<= to_integer(unsigned(word_data_next(15 downto 0)));
						wait_detect_from_s2			<= '1';
						state								<= s_wait;
					else
						state								<= s3;
						word_data_current 			<= mem_data_i;
						q_cnt								<= to_integer(unsigned(mem_data_i(30 downto 28))); 
						q_cnt2							<= to_integer(unsigned(mem_data_i(30 downto 28)));
					end if;

				--	
				when s3 =>
					mem_rd_en 							<= '0';--raz
					--
					if q_cnt = 0 then
						q_cnt2							<= 6;
						--
						if 		word_data_next(31 downto 28) = "1111" then
							q_cnt							<= 7;--bidon
							ch_word4b 					<= ch_word4b_Idle;
							mem_addr						<= 0;							
							state							<= s_loop; 
						elsif		word_data_next(31 downto 28) = "1000" then
							q_cnt							<= 7;--bidon			
							ch_word4b 					<= ch_word4b_Idle;
							wait_cnt						<= to_integer(unsigned(word_data_next(15 downto 0)));
							wait_detect_from_s3		<= '1';
							state							<= s_wait;	
						else
							q_cnt							<= to_integer(unsigned(word_data_next(30 downto 28))) - 1;
							ch_word4b					<= word_data_next(27 downto 24);
							mem_rd_en 					<= '1';
							mem_addr						<= mem_addr + 1;							
							word_data_current			<= word_data_next;
							state							<= s3;
						end if;
					--
					else
						q_cnt 							<= q_cnt - 1;
						q_cnt2							<= q_cnt2 - 1;						
						--ch_word4b						<= word_data_current(q_cnt*4-1 downto q_cnt*4-4);
						ch_word4b						<= word_data_current(q_cnt2*4-1 downto q_cnt2*4-4);
					end if;
				--
				when s_wait =>
					--	
					if wait_cnt = 0 then
						if wait_detect_from_s2 = '1' then				
							wait_detect_from_s2		<= '0';
							mem_rd_en 					<= '1';
							mem_addr						<= mem_addr + 1;							
							state 						<= s2;
						else --from s3
							wait_detect_from_s3		<= '0';							
							--state 						<= s0_bis;
							mem_addr						<= mem_addr + 1;
							mem_rd_en 					<= '1';
							state 						<= s1;
						end if;
					--
					else
						wait_cnt 						<= wait_cnt - 1;
					end if;

				--
				when s_loop =>
					if loop_cnt = 0 then
						state 							<= s_end;
					else
						loop_cnt 						<= loop_cnt - 1;
--						state 							<= s1;
--						mem_rd_en 						<= '1';
						state 						<= s0_bis;	
					end if;
				--
				when s_end =>
					if start_i = '0' then
						state 							<= s0;
					end if;
				--
				when others =>
					null;
			--
			end case;
		--
		end if;
	--
	end process;
					

	word_data_next <= mem_data_i;



--	process
--	begin
--	wait until rising_edge(clk_i);	-- rising clock edge
--		--
--		if sclr_i = '1' then
--			ch_word4b 									<= ch_word4b_Idle; 
--			mem_rd_en 									<= '0';
--			mem_cs										<= '0';
--			mem_addr										<= 0;			
--			q_cnt											<= 7;
--			q_cnt2										<= 7;			
--			wait_cnt										<= 0;
--			loop_cnt										<= 0;
--			--
--			wait_detect_from_s2						<= '0';		
--			wait_detect_from_s3						<= '0';				
--			state 										<= s0;
--		else
--		--
--			--
--			case state is
--				--
--				when s0 =>
--					mem_addr								<= 0;
--					loop_cnt 							<= to_integer(unsigned(loop_nb_i));
--					wait_detect_from_s2				<= '0';		
--					wait_detect_from_s3				<= '0';						
--					--
--					if start_i = '1' then -- and ( (trigger_i = '1' and trigger_mode_i = '1') or trigger_mode_i = '0' )  then
--						mem_rd_en 						<= '1';
--						mem_cs							<= '1';						
--						state 							<= s1;
--					else
--						mem_cs							<= '0';					
--						ch_word4b	 					<= ch_word4b_Idle;
--					end if;
--
--				--
--				when s1 =>
--					mem_addr								<= mem_addr + 1;
--					--word_data_current 				<= mem_data_i;
--					state									<= s2;
--
--				--
--				when s2 =>	
--					mem_rd_en 							<= '0';
--					--
----					state									<= s3;
----					word_data_current 				<= mem_data_i;
----					q_cnt									<= to_integer(unsigned(mem_data_i(30 downto 28))); 
----					q_cnt2								<= to_integer(unsigned(mem_data_i(30 downto 28)));	
--					--
--					if mem_data_i(31 downto 28) = "1111" then
--						q_cnt								<= 7;--bidon
--						ch_word4b 						<= ch_word4b_Idle;
--						mem_addr							<= 0;							
--						state								<= s_loop; 
--					elsif mem_data_i(31 downto 28) = "1000" then
--						q_cnt								<= 7;--bidon			
--						ch_word4b 						<= ch_word4b_Idle;
--						wait_cnt							<= to_integer(unsigned(word_data_next(15 downto 0)));
--						wait_detect_from_s2			<= '1';
--						state								<= s_wait;
--					else
--						state								<= s3;
--						word_data_current 			<= mem_data_i;
--						q_cnt								<= to_integer(unsigned(mem_data_i(30 downto 28))); 
--						q_cnt2							<= to_integer(unsigned(mem_data_i(30 downto 28)));
--					end if;
--				--	
--				when s3 =>
--					mem_rd_en 							<= '0';--raz
--					--
--					if q_cnt = 0 then
--						q_cnt2							<= 6;
--						--
--						if 		word_data_next(31 downto 28) = "1111" then
--							q_cnt							<= 7;--bidon
--							ch_word4b 					<= ch_word4b_Idle;
--							mem_addr						<= 0;							
--							state							<= s_loop; 
--						elsif		word_data_next(31 downto 28) = "1000" then
--							q_cnt							<= 7;--bidon			
--							ch_word4b 					<= ch_word4b_Idle;
--							wait_cnt						<= to_integer(unsigned(word_data_next(15 downto 0)));
--							wait_detect_from_s3		<= '1';
--							state							<= s_wait;	
--						else
--							q_cnt							<= to_integer(unsigned(word_data_next(30 downto 28))) - 1;
--							ch_word4b					<= word_data_next(27 downto 24);
--							mem_rd_en 					<= '1';
--							mem_addr						<= mem_addr + 1;							
--							word_data_current			<= word_data_next;
--							state							<= s3;
--						end if;
--					--
--					else
--						q_cnt 							<= q_cnt - 1;
--						q_cnt2							<= q_cnt2 - 1;						
--						--ch_word4b						<= word_data_current(q_cnt*4-1 downto q_cnt*4-4);
--						ch_word4b						<= word_data_current(q_cnt2*4-1 downto q_cnt2*4-4);
--					end if;
--				--
--				when s_wait =>
--					--	
--					if wait_cnt = 0 then
--						if wait_detect_from_s2 = '1' then				
--							wait_detect_from_s2		<= '0';
--							state 						<= s2;
--						else --from s3
--							wait_detect_from_s3		<= '0';
--							state 						<= s1;
--						end if;
--						mem_rd_en 						<= '1';
--						mem_addr							<= mem_addr + 1;
--					else
--						wait_cnt 						<= wait_cnt - 1;
--					end if;
--					--	
----					if wait_cnt = 0 then
----						if wait_detect_from_s2 = '1' then				
----							wait_detect_from_s2		<= '0';
----							mem_rd_en 					<= '1';
----							mem_addr						<= mem_addr + 1;							
----							state 						<= s2;
----						elsif  ( (trigger_i = '1' and trigger_mode_i = '1') or trigger_mode_i = '0' ) then --from s3
----							wait_detect_from_s3		<= '0';
----							mem_rd_en 					<= '1';
----							mem_addr						<= mem_addr + 1;							
----							state 						<= s1;
----						end if;
----					--
----					else
----						wait_cnt 						<= wait_cnt - 1;
----					end if;
--				--
--				when s_loop =>
--					if loop_cnt = 0 then
--						state 							<= s_end;
--					else
--						loop_cnt 						<= loop_cnt - 1;
--						state 							<= s1;
--						mem_rd_en 						<= '1';	
--					end if;
--				--
--				when s_end =>
--					if start_i = '0' then
--						state 							<= s0;
--					end if;
--				--
--				when others =>
--					null;
--			--
--			end case;
--		--
--		end if;
--	--
--	end process;
					
						


	word_data_next <= mem_data_i;

	

end Behavioral;


--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                 	IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	PIXFED / CMS Pixel Upgrade Phase I (VME -> uTCA technology)                                                               
-- Module Name:             	fmcfitel_i2c_manager_v3.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.1                                                                      
--
-- Description:           		* Drives the transfer of the I2C transactions contained into the FIFO TX to the FMCFITEL
--										* receiver when a start is request from s/w
-- 				             	* First the s/w has to fill-in the FIFO TX by respecting the format defined by IPHC
-- 				             	* Secondly, the s/w has to send the start request to perform read or write accesses 
-- 				             	* The I2C transactions are sent one after another one until the FIFO TX becomes empty
-- 				             	* For a read access, the data from the slave's register is stored into the FIFO RX
-- 				             	* For a write access, the FIFO RX is filled-in too (a read of the FIFO RX is to be 
-- 				             	* Finally, the s/w has to read the acknoledge status to verify that the transactions have been well executed
-- 				             	* and read all the contents of the FIFO RX
-- 
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	2015/09/01   0.1       	LCHARLES          - First .vhd file 
--                                                                  
--
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--


library ieee;
use ieee.std_logic_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--! system packages

--! user packages





entity fmcfitel_i2c_manager_v3 is
--	generic (	CLK_PRESCALER 								: std_logic_vector(15 downto 0) := x"004f"
--				);

	port ( 		--===============--
					-- GENERAL --
					--===============--	
					clk_i											: in std_logic;
					sclr_i 										: in std_logic;
					--===============--
					-- SW INTERFCACE --
					--===============--					
					--Cmd Rq
					from_sw_i2c_cmd_req_i					: in std_logic_vector(1 downto 0); 	--"00" or "10": NO / "11": RD / "01": WR 
					--Cmd Ack
					to_sw_i2c_cmd_ack_o						: out std_logic_vector(1 downto 0); --"00": idle or wait / "01": ACK GOOD / "10": ACK KO
					--i2c slave @
					from_sw_i2c_slave_addr_i 				: in std_logic_vector(6 downto 0); 
					--=================--
					-- FIFO INTERFACE --
					--=================--	
					--TX
					fifo_tx_rd_en_o							: out std_logic;
					fifo_tx_empty_i							: in std_logic;
					fifo_tx_valid_i							: in std_logic;
					fifo_tx_dout_i								: in std_logic_vector(31 downto 0);
					--RX
					fifo_rx_wr_en_o							: out std_logic;
					fifo_rx_din_o								: out std_logic_vector(31 downto 0);					
					--==============--
					-- I2C_PHY_CTRL --
					--==============--
					i2c_master_reset_n_o						: out std_logic;
					i2c_master_ctrl_reg_o 					: out std_logic_vector(7 downto 0);
					i2c_master_clk_prescaler_o 			: out std_logic_vector(15 downto 0);
					i2c_master_tx_reg_o 						: out std_logic_vector(7 downto 0);
					i2c_master_rx_reg_i						: in std_logic_vector(7 downto 0);
					i2c_master_stat_reg_i					: in std_logic_vector(7 downto 0);
					i2c_master_cmd_reg_strobe_o			: out std_logic;
					i2c_master_cmd_reg_o						: out std_logic_vector(7 downto 0);
					--========--
					-- STATUS --
					--========--
					i2c_access_busy_o							: out std_logic;
					--
					fmcfitel_device_index_o					: out std_logic_vector(0 downto 0);
					fmcfitel_fmc_index_o						: out std_logic_vector(0 downto 0)				
					
				);

end fmcfitel_i2c_manager_v3;



architecture Behavioral of fmcfitel_i2c_manager_v3 is

   --========================= Signals Declaration ==========================--


   -- I2C_PHY_CTRL:
   ----------------
	signal i2c_master_reset_n							: std_logic := '0';--EN
	signal i2c_master_ctrl_reg 						: std_logic_vector(7 downto 0) := (others => '0');
	signal i2c_master_clk_prescaler 					: std_logic_vector(15 downto 0) := (others => '0');
	signal i2c_master_tx_reg 							: std_logic_vector(7 downto 0) := (others => '0');
	signal i2c_master_cmd_reg_strobe					: std_logic := '0'; --DIS
	signal i2c_master_cmd_reg							: std_logic_vector(7 downto 0) := (others => '0');

	signal i2c_access_busy								: std_logic := '0'; --DIS


--	--CONSTANT:
--	-----------
--	constant FITELFMC_I2C_ADDR 						: std_logic_vector(7 downto 0) := x"4D";
--
--	--SIGNALS:
--	----------
--	signal 	I2C_CTRL_ACCESS_MODE 					: std_logic := '0'; --'0' : RD / '1' : WR		
--	signal 	I2C_CTRL_SLAVE_ADDR 						: std_logic_vector(6 downto 0):= (others => '0');	
--	signal 	I2C_CTRL_REG_ADDR 						: std_logic_vector(7 downto 0):= (others => '0');
--	signal 	I2C_CTRL_REG_DATA 						: std_logic_vector(7 downto 0):= (others => '0');
--
--	--TRANSACTIONS MAP:
--	-------------------
--	constant TRANSACTIONS_NB 							: integer := 3;
--	signal transaction_counter 						: integer range 0 to TRANSACTIONS_NB-1 := 0;
--
--	type transaction_reg_type 							is array(TRANSACTIONS_NB-1 downto 0) 	of std_logic_vector(15 downto 0);	
--	signal transaction_reg 								: transaction_reg_type;
	
	
	
	--FSM:
	------
	type state_type is 	(	idle, s1, s2, sr1, sr2, sr3, sr4, sr5, sr6, sr7, sr8, sr9, sr10, sr11, sr12, sw1, sw2, sw3, s_end 
								); 						
	signal state : state_type;		



	--SW INTERFCACE:
	----------------
	signal to_sw_i2c_cmd_ack 							: std_logic_vector(to_sw_i2c_cmd_ack_o'range) := (others => '0');


	--FIFOs:
	--------
	signal fifo_tx_rd_en									: std_logic := '0';
	signal fifo_rx_wr_en									: std_logic := '0';
	signal fifo_rx_din 									: std_logic_vector(31 downto 0) := (others => '0');
	
	
	--INDEX:
	--------
	signal fmcfitel_device_index						: std_logic_vector(0 downto 0) := (others => '0');
	signal fmcfitel_fmc_index							: std_logic_vector(0 downto 0) := (others => '0');



	--STATUS:
	---------
	signal ack_error										: std_logic := '0';


   --========================================================================--   
 
--===========================================================================--
-----        --===================================================--
begin      --================== Architecture Body ==================-- 
-----        --===================================================--
--===========================================================================--
   
   --============================= User Logic ===============================--


	--Start I/O mapping
	to_sw_i2c_cmd_ack_o 									<= to_sw_i2c_cmd_ack;

	i2c_master_reset_n_o									<= i2c_master_reset_n;
	i2c_master_ctrl_reg_o								<= i2c_master_ctrl_reg;
--	i2c_master_clk_prescaler_o							<= x"0010"; --x"004f"; --i2c_master_clk_prescaler; 
	i2c_master_clk_prescaler_o							<= x"004f"; --i2c_master_clk_prescaler; 
	i2c_master_tx_reg_o									<= i2c_master_tx_reg;
	i2c_master_cmd_reg_strobe_o						<= i2c_master_cmd_reg_strobe;
	i2c_master_cmd_reg_o									<= i2c_master_cmd_reg;

	i2c_access_busy_o										<= i2c_access_busy;

	--
	fifo_tx_rd_en_o										<= fifo_tx_rd_en;
	fifo_rx_wr_en_o										<= fifo_rx_wr_en;
	fifo_rx_din_o											<= fifo_rx_din;

	--
--	fmcfitel_device_index_o								<= fmcfitel_device_index; 
--	fmcfitel_fmc_index_o									<= fmcfitel_fmc_index;  
--	fmcfitel_device_index_o(0)							<= fifo_tx_dout_i(20); --fmcfitel_device_index; 
--	fmcfitel_fmc_index_o(0)								<= fifo_tx_dout_i(24); --fmcfitel_fmc_index;  	


	process (fifo_tx_valid_i, fifo_tx_dout_i)
	begin
		if fifo_tx_valid_i = '1' then
			fmcfitel_device_index(0)							<= fifo_tx_dout_i(20);
			fmcfitel_fmc_index(0)								<= fifo_tx_dout_i(24);
		end if;
	end process;
	fmcfitel_device_index_o 									<= fmcfitel_device_index;
	fmcfitel_fmc_index_o 										<= fmcfitel_fmc_index;

	--End I/O mapping
	



	--===============================================================================================--
	process --FSM
	--===============================================================================================--
	begin
	wait until clk_i'event and clk_i = '1';
		--
		if sclr_i = '1' then  
			--I2C_PHY_CTRL			
			i2c_master_reset_n								<= '0'; --EN
			i2c_master_ctrl_reg								<= "00" & "000000"; --core dis
			--
			i2c_access_busy	 								<= '0';	
			--SW status
			to_sw_i2c_cmd_ack									<= "00"; --idle
			--fifo CTRL 
			fifo_tx_rd_en 										<= '0'; --'1' : EN / '0' : DIS	
			fifo_rx_wr_en 										<= '0'; --'1' : EN / '0' : DIS			
			--
			fifo_rx_din											<= (others => '0');
			--
			ack_error											<= '0';
			--
			state													<= idle;
		--	
		else
			case state is
				--
				when idle =>
					--
					if from_sw_i2c_cmd_req_i(0) = '1' then --req en?
						state 									<= s1; 
						--I2C_PHY_CTRL = EN
						i2c_master_reset_n					<= '1'; --DIS
						i2c_master_ctrl_reg					<= "10" & "000000"; --core en
						--
						i2c_access_busy	 					<= '0';
					else
						--I2C_PHY_CTRL = DIS
						i2c_master_reset_n					<= '0'; --EN
						i2c_master_ctrl_reg					<= "00" & "000000"; --core dis
						--
						i2c_access_busy	 					<= '0';						
						--SW status
						to_sw_i2c_cmd_ack						<= "00"; --idle
						--fifo CTRL 
						fifo_tx_rd_en 							<= '0'; --'1' : EN / '0' : DIS
						fifo_rx_wr_en 							<= '0'; --'1' : EN / '0' : DIS							
						--
						fifo_rx_din								<= (others => '0');
						--	
						ack_error								<= '0';	
						--
					end if;
					--
				--
				when s1 => 			
					--
					fifo_rx_wr_en 								<= '0'; --DIS					
					--
					if fifo_tx_empty_i = '1' then
						state 									<= s_end; --end				
						--					
					else
						fifo_tx_rd_en 							<= '1'; --EN
						state 									<= s2;					
					end if;
					--
				--
				when s2 => 
					--
					i2c_access_busy	 						<= '1'; --EN
					fifo_tx_rd_en 								<= '0'; --DIS
					--
					if fifo_tx_valid_i = '1' then
						state 									<= sr1; --common
					end if;

				--READ ACCESS --commonn READ / WRITE
				--
				when sr1 => 
					i2c_master_tx_reg 						<= from_sw_i2c_slave_addr_i & '0'; --slave@ + wr
					i2c_master_cmd_reg						<=	"10010000"; --(7): sta ; (4): wr				
					i2c_master_cmd_reg_strobe				<= '1'; --EN
					state											<= sr2;
				--
				when sr2 => 	
					i2c_master_cmd_reg_strobe				<= '0'; --DIS
					--state											<= sr3;
					--
					if i2c_master_stat_reg_i(1) = '1' then --wait TIP active 
						state 									<= sr3;
					end if;						
					--
				--
				when sr3 => 
--					--
--					if i2c_master_stat_reg_i(1) = '0' and i2c_master_stat_reg_i(7) = '0' then --TIP + ACK
--						state 									<= sr4; 
--					--else
--						--error
--					end if;

					if i2c_master_stat_reg_i(1) = '0' then --TIP
						if i2c_master_stat_reg_i(7) = '0' then--ACK
							state 								<= sr4;
						else
							ack_error							<= '1'; --flag
							--state 						   	<= s_end;
							state 						   	<= sr4; --continue
						end if;
					end if;


				--
				when sr4 => 
					i2c_master_tx_reg 						<= fifo_tx_dout_i(15 downto 8); --reg@
					--i2c_master_cmd_reg						<=	"01010000"; --(6): sto ; (4): wr				
					i2c_master_cmd_reg						<=	'0' & from_sw_i2c_cmd_req_i(1) & "010000"; --(6): sto ; (4): wr
					-->if WRITE ACCESS <=> from_sw_i2c_cmd_req_i(1) = 0 <=> no sto
					-->if READ  ACCESS <=> from_sw_i2c_cmd_req_i(1) = 1 <=> sto
					i2c_master_cmd_reg_strobe				<= '1'; --EN
					state											<= sr5;
				--
				when sr5 => 	
					i2c_master_cmd_reg_strobe				<= '0'; --DIS
					--state											<= sr6;
					--
					if i2c_master_stat_reg_i(1) = '1' then --wait TIP active 
						state 									<= sr6;
					end if;						
					--
				--
				when sr6 => 
--					--
--					if i2c_master_stat_reg_i(1) = '0' and i2c_master_stat_reg_i(7) = '0' then --TIP + ACK
--						state 									<= sr7;
--					--else
--						--error
--					end if;

					if i2c_master_stat_reg_i(1) = '0' then --TIP
						if i2c_master_stat_reg_i(7) = '0' then --ACK
							if from_sw_i2c_cmd_req_i(1) = '1' then --RD ACCESS?
								state 							<= sr7;
							else
								state 							<= sw1;
							end if;
						else
							ack_error							<= '1';
--							state 						   	<= s_end;
							if from_sw_i2c_cmd_req_i(1) = '1' then --RD ACCESS?
								state 							<= sr7;
							else
								state 							<= sw1;
							end if;
						end if;
					end if;



				--
				when sw1 => 
					i2c_master_tx_reg 						<= fifo_tx_dout_i(7 downto 0); --regData
					i2c_master_cmd_reg						<=	"01010000"; --(6): sto ; (4): wr				
					i2c_master_cmd_reg_strobe				<= '1'; --EN
					state											<= sw2;

				--
				when sw2 => 	
					i2c_master_cmd_reg_strobe				<= '0'; --DIS
					--
					if i2c_master_stat_reg_i(1) = '1' then --wait TIP active 
						state 									<= sw3;
					end if;						
					--
				--
				when sw3 => 
					--
					if i2c_master_stat_reg_i(1) = '0' then --TIP
						if i2c_master_stat_reg_i(7) = '0' then--ACK
							state 								<= s1;
						else
							ack_error							<= '1';
							--state 						   	<= s_end;
							state 						   	<= s1;
						end if;
					end if;
					--


				--
				when sr7 => 
					i2c_master_tx_reg 						<= from_sw_i2c_slave_addr_i & '1'; --slave@ + rd
					i2c_master_cmd_reg						<=	"10010000"; --(7): sta ; (4): wr				
					i2c_master_cmd_reg_strobe				<= '1'; --EN
					state											<= sr8;
				--
				when sr8 => 	
					i2c_master_cmd_reg_strobe				<= '0'; --DIS
					--state											<= sr9;
					--
					if i2c_master_stat_reg_i(1) = '1' then --wait TIP active 
						state 									<= sr9;
					end if;						
					--
				--
				when sr9 => 
--					--
--					if i2c_master_stat_reg_i(1) = '0' and i2c_master_stat_reg_i(7) = '0' then --TIP + ACK
--						state 									<= sr10;
--					--else
--						--error
--					end if;

					if i2c_master_stat_reg_i(1) = '0' then --TIP
						if i2c_master_stat_reg_i(7) = '0' then--ACK
							state 								<= sr10;
						else
							ack_error							<= '1';
							--state 						   	<= s_end;
							state 						   	<= sr10;
						end if;
					end if;

				--
				when sr10 => 
					i2c_master_cmd_reg						<=	"01101000"; --(6): sto ; (5): rd	 ; (3): nack		
					i2c_master_cmd_reg_strobe				<= '1'; --EN
					state											<= sr11;
				--
				when sr11 => 	
					i2c_master_cmd_reg_strobe				<= '0'; --DIS
					--state											<= sr12;
					--
					if i2c_master_stat_reg_i(1) = '1' then --wait TIP active 
						state 									<= sr12;
					end if;						
					--
				--
				when sr12 => 	
					if i2c_master_stat_reg_i(1) = '0' then --TIP
						--
						fifo_rx_wr_en 							<= '1'; --EN
						fifo_rx_din(31 downto 8)			<= fifo_tx_dout_i(31 downto 8);
						--
						if from_sw_i2c_cmd_req_i(1) = '1' then  --RD MODE?
							fifo_rx_din(7 downto 0) 		<= i2c_master_rx_reg_i(7 downto 0); 
						else
							fifo_rx_din(7 downto 0)			<= fifo_tx_dout_i(7 downto 0); --could be removed!!!
						end if;
						--
						state										<= s1;
						--
					end if;


				--
				when s_end => --end
					--
					if from_sw_i2c_cmd_req_i(0) = '0' then --req dis?
						to_sw_i2c_cmd_ack						<= "00"; --idle
						state										<= idle;
					else
						--to_sw_i2c_cmd_ack						<= "01"; --good
						to_sw_i2c_cmd_ack						<= ack_error & '1'; --ok : "01" / ko : "11"						
					end if;
					--

				--
				when others =>
					null;
			end case;
		end if;
	end process;

					




end Behavioral;


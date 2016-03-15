--=================================================================================================--
--==================================== Module Information =========================================--
--=================================================================================================--
--                                                                                         
-- Company:                 	IPHC Laboratory (CNRS/Strasbourg)                                                         
-- Engineer:                	Laurent CHARLES (lcharles@iphc.cnrs.fr) 
--                                                                                                  
-- Project Name:            	FEC / CMS Tracker Upgrade (VME -> uTCA technology)                                                               
-- Module Name:             	fmc_8sfp_i2c_manager.vhd                                       
--                                                                                                  
-- Language:               	VHDL'93                                                                  
--                                                                                                    
-- Target Device:           	Device agnostic                                                         
-- Tool version: 				   ISE14.6                                                                    
--                                                                                                    
-- Version:                 	0.1                                                                      
--
-- Description:             	* Enable the TX from all SFPs from fmc8sfp mezzanine
--										* Initialisation made in hard after startup  
-- 
-- Versions history:        	DATE         VERSION   	AUTHOR            DESCRIPTION
--
--                          	20/11/2014   0.1       	LCHARLES          - First .vhd file 
--                                                                  
--
-- Additional Comments:                                                                             
--                                                                                                    
--=================================================================================================--
--=================================================================================================--


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--! user packages
--! IPHC PKG
use work.pkg_glib_pix_emul.all;

entity fmc_8sfp_i2c_manager is
	port ( 		--===============--
					-- GENERAL --
					--===============--	
					clk_i											: in std_logic;
					reset_n_i 									: in std_logic;
						
					--==============--
					-- I2C_PHY_CTRL --
					--==============--
					--From I2C Controller		
					i2c_ctrl_reply_i							: in std_logic_vector(31 downto 0);				
					i2c_ctrl_done_i							: in std_logic;
					--Towards I2C Controller
					i2c_ctrl_settings_o						: out std_logic_vector(31 downto 0);
					i2c_ctrl_command_o						: out std_logic_vector(31 downto 0);
							
					--========--
					-- STATUS --
					--========--
					i2c_access_busy_o							: out std_logic
					
				);

end fmc_8sfp_i2c_manager;

architecture Behavioral of fmc_8sfp_i2c_manager is


   --==============--
   -- I2C_PHY_CTRL --
   --==============--
	
	--CONSTANTS:
	------------
	--I2C settings	
	-->DIS
	constant I2C_CTRL_DIS 								: std_logic_vector(31 downto 0) := x"00000000";
	-->EN
		--i2c_en = 1 => b11
		--i2c_sel = 0 (line 0) => b10
		--i2c_presc = 500 ([0:1023]) => b9:b0
		--> f(scl) = 62.5M/i2c_presc = 125kHz	
	constant I2C_CTRL_EN 								: std_logic_vector(31 downto 0) := x"000009F4"; 
	--> I2C cmd
	constant I2C_CTRL_STROBE 							: std_logic := '1'; --'1' => strobe en
	constant I2C_CTRL_16b_MODE 						: std_logic := '0'; --'0' => 8b 
	constant I2C_CTRL_RAL_MODE 						: std_logic := '0'; --'1' => RAL MODE / '0' => STD
	constant I2C_DUMMY_BYTE 							: std_logic_vector(7 downto 0) := x"00";
	constant I2C_CTRL_RD_MODE 							: std_logic := '0';
	constant I2C_CTRL_WR_MODE 							: std_logic := '1'; 
	
	--SIGNALS:
	----------
	signal 	I2C_CTRL_ACCESS_MODE 					: std_logic := '0'; --'0' : RD / '1' : WR		
	signal 	I2C_CTRL_SLAVE_ADDR 						: std_logic_vector(6 downto 0):= (others => '0');	
	signal 	I2C_CTRL_REG_ADDR 						: std_logic_vector(7 downto 0):= (others => '0');
	signal 	I2C_CTRL_REG_DATA 						: std_logic_vector(7 downto 0):= (others => '0');

	--TRANSACTIONS MAP:
	-------------------
	constant TRANSACTIONS_MAX_NB 						: integer := 6; --max
	signal transaction_counter 						: integer range 0 to TRANSACTIONS_MAX_NB-1 := 0;
	signal transactions_nb								: integer range 0 to TRANSACTIONS_MAX_NB-1 := 0;

	type transaction_reg_type 							is array(TRANSACTIONS_MAX_NB-1 downto 0) 	of std_logic_vector(15 downto 0);	
	signal transaction_reg 								: transaction_reg_type;
	
	
	
	--FSM:
	------
	type state_type is 	(	idle, s1, s2, s3, s4, s5, s6 
								); 						
	signal state : state_type;		

begin

------	--VIA FMC2
------	--PCA9548APW
------	transaction_reg(2) <= x"EE_04"; --the first one!!!
------	--PCA8574APW
------	transaction_reg(1) <= x"70_00";
------	--PCA9548APW
------	transaction_reg(0) <= x"EE_00"; 	
----	
----	--VIA FMC1	
----	--PCA9548APW
----	transaction_reg(2) <= x"E8_04";
----	--PCA8574APW
----	transaction_reg(1) <= x"70_00";
----	--PCA9548APW
----	transaction_reg(0) <= x"E8_00"; 	
--	
--		
--	sfp_fmc1_used_gen	: if sfp_fmc_used = fmc1_j2 generate	
--		--VIA FMC1	
--		--PCA9548APW
--		transaction_reg(2) <= x"E8_04"; --CH2 EN	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL
--		--PCA8574APW
--		transaction_reg(1) <= x"70_00"; -- [P7:P0] = x"00" <=> SFP_TX_DIS(A,B,C,D,E,F,G,H) = 0 <=> TX(all_SFPs) active
--		--PCA9548APW
--		transaction_reg(0) <= x"E8_00"; --CH2 DIS	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL
--	end generate;
--	
--	
--	sfp_fmc2_used_gen	: if sfp_fmc_used = fmc2_j1 generate	
--		--VIA FMC2
--		--PCA9548APW
--		transaction_reg(2) <= x"EE_04"; --CH2 EN	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL 
--		--PCA8574APW
--		transaction_reg(1) <= x"70_00"; -- [P7:P0] = x"00" <=> SFP_TX_DIS(A,B,C,D,E,F,G,H) = active
--		--PCA9548APW
--		transaction_reg(0) <= x"EE_00"; --CH2 DIS	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL 	 
--	end generate;	
	


	fmc8sfp_on_fmc1_j2_AND_on_fmc2_j1_gen : if fmc1_j2_type = "fmc8sfp" and fmc2_j1_type = "fmc8sfp" generate
		--VIA FMC1	
		--PCA9548APW
		transaction_reg(5) <= x"E8_04"; --CH2 EN	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL
		--PCA8574APW
		transaction_reg(4) <= x"70_00"; -- [P7:P0] = x"00" <=> SFP_TX_DIS(A,B,C,D,E,F,G,H) = 0 <=> TX(all_SFPs) active
		--PCA9548APW
		transaction_reg(3) <= x"E8_00"; --CH2 DIS	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL
		--VIA FMC2
		--PCA9548APW
		transaction_reg(2) <= x"EE_04"; --CH2 EN	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL 
		--PCA8574APW
		transaction_reg(1) <= x"70_00"; -- [P7:P0] = x"00" <=> SFP_TX_DIS(A,B,C,D,E,F,G,H) = active
		--PCA9548APW
		transaction_reg(0) <= x"EE_00"; --CH2 DIS	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL 
		--
		transactions_nb 	 <= 5;-- <=> 6
	end generate;


	fmc8sfp_on_fmc1_j2_ONLY_gen : if fmc1_j2_type = "fmc8sfp" and fmc2_j1_type /= "fmc8sfp" generate
		--VIA FMC1	
		--PCA9548APW
		transaction_reg(2) <= x"E8_04"; --CH2 EN	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL
		--PCA8574APW
		transaction_reg(1) <= x"70_00"; -- [P7:P0] = x"00" <=> SFP_TX_DIS(A,B,C,D,E,F,G,H) = 0 <=> TX(all_SFPs) active
		--PCA9548APW
		transaction_reg(0) <= x"E8_00"; --CH2 DIS	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL
		--
		transactions_nb 	 <= 2;-- <=> 3
	end generate;

	fmc8sfp_on_fmc2_j1_ONLY_gen : if fmc2_j1_type = "fmc8sfp" and fmc1_j2_type /= "fmc8sfp" generate
		--VIA FMC2
		--PCA9548APW
		transaction_reg(2) <= x"EE_04"; --CH2 EN	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL 
		--PCA8574APW
		transaction_reg(1) <= x"70_00"; -- [P7:P0] = x"00" <=> SFP_TX_DIS(A,B,C,D,E,F,G,H) = active
		--PCA9548APW
		transaction_reg(0) <= x"EE_00"; --CH2 DIS	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL 
		--
		transactions_nb 	 <= 2;-- <=> 3
	end generate;
	
--		--VIA FMC1	
--		--PCA9548APW
--		transaction_reg(2) <= x"E8_04"; --CH2 EN	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL
--		--PCA8574APW
--		transaction_reg(1) <= x"70_00"; -- [P7:P0] = x"00" <=> SFP_TX_DIS(A,B,C,D,E,F,G,H) = 0 <=> TX(all_SFPs) active
--		--PCA9548APW
--		transaction_reg(0) <= x"E8_00"; --CH2 DIS	: SFP_TX_DIS_SDA and SFP_TX_DIS_SCL
--		--
--		transactions_nb 	 <= 2;-- <=> 3
		
	--===============================================================================================--
	process (clk_i, reset_n_i) --FSM
	--===============================================================================================--
	begin
		--
		if reset_n_i = '0' then
			i2c_ctrl_settings_o 							<= I2C_CTRL_DIS;
			transaction_counter							<= transactions_nb; --TRANSACTIONS_NB-1;
			i2c_ctrl_command_o							<= (others =>'0');
			--STATUS
			i2c_access_busy_o 							<= '0';			
			state												<= idle;
		--
		elsif clk_i'event and clk_i = '1' then
			case state is
				--
				when idle =>
					i2c_ctrl_settings_o 					<= I2C_CTRL_DIS;
					transaction_counter					<= transactions_nb; --TRANSACTIONS_NB-1;
					i2c_ctrl_command_o					<= (others =>'0');
					--STATUS
					i2c_access_busy_o 					<= '0';					
					state 									<= s1;	
				--
				when s1 =>
					i2c_ctrl_settings_o 					<= I2C_CTRL_EN;
					--STATUS
					i2c_access_busy_o 					<= '1';						
					state 									<= s2;
				--
				when s2 =>
					--I2C_PHY_CTRL : COMMAND TMP 
					--> Slave@
					I2C_CTRL_SLAVE_ADDR					<= transaction_reg(transaction_counter)(15 downto 9);
					--> Reg@
					--not used in STD mode
					--> RegData
					I2C_CTRL_REG_DATA 					<= transaction_reg(transaction_counter)(7 downto 0);	
					--> AccessMode
					I2C_CTRL_ACCESS_MODE 				<= not transaction_reg(transaction_counter)(8); --'0' : Rd / '1' : Wr --> reversed / I2C Protocol
					--
					state 									<= s3;
				--
				when s3 =>
					--I2C_PHY_CTRL : COMMAND AFFECTATION
					i2c_ctrl_command_o 					<= 	I2C_CTRL_STROBE   		&
																		"00000"					 	&
																		I2C_CTRL_16b_MODE 		&
																		I2C_CTRL_RAL_MODE 		&
																		I2C_CTRL_ACCESS_MODE 	&
																		I2C_CTRL_SLAVE_ADDR		&
																		I2C_CTRL_REG_ADDR			&
																		I2C_CTRL_REG_DATA;
					--
					state 									<= s4;				
				--
				when s4 =>
					--I2C_PHY_CTRL : COMMAND / STROBE RAZ
					i2c_ctrl_command_o(31 downto 28) <= (others => '0'); 
					
					--WAITING REPLY FROM I2C_PHY_CTRL
					if i2c_ctrl_done_i = '1' then --one pulse from I2C_PHY_CTRL
						state <= s5;
					end if;
				--
				when s5 =>
					--
					if transaction_counter = 0 then
						state 								<= s6;
					else
						transaction_counter 				<= transaction_counter - 1;
						state 								<= s1;
					end if;
					--
				--
				when s6 =>
					--STATUS
					i2c_access_busy_o 					<= '0';
					i2c_ctrl_settings_o 					<= I2C_CTRL_DIS;					
			end case;
		end if;
	end process;
					




end Behavioral;


# TCL File Generated by Component Editor 11.1
# Sun Jan 14 21:35:18 CET 2018
# DO NOT MODIFY


# +-----------------------------------
# | 
# | spi_master "new_component" v1.0
# | null 2018.01.14.21:35:18
# | 
# | 
# | C:/Users/this-pc/Desktop/Projects_VHDL/SPI_Implemenation/spi_master.vhd
# | 
# |    ./spi_master.vhd syn, sim
# | 
# +-----------------------------------

# +-----------------------------------
# | request TCL package from ACDS 11.0
# | 
package require -exact sopc 11.0
# | 
# +-----------------------------------

# +-----------------------------------
# | module spi_master
# | 
set_module_property NAME spi_master
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property DISPLAY_NAME new_component
set_module_property TOP_LEVEL_HDL_FILE spi_master.vhd
set_module_property TOP_LEVEL_HDL_MODULE spi_master
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL TRUE
set_module_property STATIC_TOP_LEVEL_MODULE_NAME spi_master
set_module_property FIX_110_VIP_PATH false
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file spi_master.vhd {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter slaves INTEGER 4
set_parameter_property slaves DEFAULT_VALUE 4
set_parameter_property slaves DISPLAY_NAME slaves
set_parameter_property slaves TYPE INTEGER
set_parameter_property slaves UNITS None
set_parameter_property slaves AFFECTS_GENERATION false
set_parameter_property slaves HDL_PARAMETER true
add_parameter d_width INTEGER 2
set_parameter_property d_width DEFAULT_VALUE 2
set_parameter_property d_width DISPLAY_NAME d_width
set_parameter_property d_width TYPE INTEGER
set_parameter_property d_width UNITS None
set_parameter_property d_width AFFECTS_GENERATION false
set_parameter_property d_width HDL_PARAMETER true
# | 
# +-----------------------------------

# +-----------------------------------
# | display items
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point clock_reset
# | 
add_interface clock_reset clock end
set_interface_property clock_reset clockRate 0

set_interface_property clock_reset ENABLED true

add_interface_port clock_reset clock reset_n Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point reset
# | 
add_interface reset reset end
set_interface_property reset associatedClock clock_reset
set_interface_property reset synchronousEdges NONE

set_interface_property reset ENABLED true

add_interface_port reset reset_n reset_n Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point nios_custom_instruction_master
# | 
add_interface nios_custom_instruction_master nios_custom_instruction start
set_interface_property nios_custom_instruction_master clockCycle 0

set_interface_property nios_custom_instruction_master ENABLED true

add_interface_port nios_custom_instruction_master enable beginbursttransfer_n Input 1
add_interface_port nios_custom_instruction_master cpol beginbursttransfer_n Input 1
add_interface_port nios_custom_instruction_master cpha beginbursttransfer_n Input 1
add_interface_port nios_custom_instruction_master cont beginbursttransfer_n Input 1
add_interface_port nios_custom_instruction_master tx_data beginbursttransfer_n Input d_width
add_interface_port nios_custom_instruction_master miso beginbursttransfer_n Input 1
add_interface_port nios_custom_instruction_master sclk readdatavalid_n Output 1
add_interface_port nios_custom_instruction_master ss_n readdatavalid_n Output slaves
add_interface_port nios_custom_instruction_master mosi readdatavalid_n Output 1
add_interface_port nios_custom_instruction_master busy readdatavalid_n Output 1
add_interface_port nios_custom_instruction_master rx_data readdatavalid_n Output d_width
# | 
# +-----------------------------------

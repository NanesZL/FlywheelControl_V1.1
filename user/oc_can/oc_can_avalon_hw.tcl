# TCL File Generated by Component Editor 13.0
# Sat Sep 24 19:37:40 GMT+08:00 2016
# DO NOT MODIFY


# 
# oc_can_avalon "oc_can_avalon" v1.0
# xiaomeige 2016.09.24.19:37:40
# 
# 

# 
# request TCL package from ACDS 13.0
# 
package require -exact qsys 13.0


# 
# module oc_can_avalon
# 
set_module_property DESCRIPTION ""
set_module_property NAME oc_can_avalon
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP CoreCourse
set_module_property AUTHOR xiaomeige
set_module_property DISPLAY_NAME oc_can_avalon
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL can_top_avalon
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file can_top_avalon.v VERILOG PATH can_top_avalon.v TOP_LEVEL_FILE
add_fileset_file can_acf.v VERILOG PATH can_acf.v
add_fileset_file can_bsp.v VERILOG PATH can_bsp.v
add_fileset_file can_btl.v VERILOG PATH can_btl.v
add_fileset_file can_crc.v VERILOG PATH can_crc.v
add_fileset_file can_defines.v VERILOG PATH can_defines.v
add_fileset_file can_fifo.v VERILOG PATH can_fifo.v
add_fileset_file can_ibo.v VERILOG PATH can_ibo.v
add_fileset_file can_register.v VERILOG PATH can_register.v
add_fileset_file can_register_asyn.v VERILOG PATH can_register_asyn.v
add_fileset_file can_register_asyn_syn.v VERILOG PATH can_register_asyn_syn.v
add_fileset_file can_register_syn.v VERILOG PATH can_register_syn.v
add_fileset_file can_registers.v VERILOG PATH can_registers.v
add_fileset_file can_testbench.v VERILOG PATH can_testbench.v
add_fileset_file can_testbench_defines.v VERILOG PATH can_testbench_defines.v
add_fileset_file can_top.v VERILOG PATH can_top.v
add_fileset_file timescale.v VERILOG PATH timescale.v


# 
# parameters
# 


# 
# display items
# 


# 
# connection point av
# 
add_interface av avalon end
set_interface_property av addressUnits WORDS
set_interface_property av associatedClock av_clk
set_interface_property av associatedReset av_reset
set_interface_property av bitsPerSymbol 8
set_interface_property av burstOnBurstBoundariesOnly false
set_interface_property av burstcountUnits WORDS
set_interface_property av explicitAddressSpan 0
set_interface_property av holdTime 0
set_interface_property av linewrapBursts false
set_interface_property av maximumPendingReadTransactions 0
set_interface_property av readLatency 0
set_interface_property av readWaitTime 1
set_interface_property av setupTime 0
set_interface_property av timingUnits Cycles
set_interface_property av writeWaitTime 0
set_interface_property av ENABLED true
set_interface_property av EXPORT_OF ""
set_interface_property av PORT_NAME_MAP ""
set_interface_property av SVD_ADDRESS_GROUP ""

add_interface_port av av_chipselect chipselect Input 1
add_interface_port av av_write write Input 1
add_interface_port av av_read read Input 1
add_interface_port av av_writedata writedata Input 8
add_interface_port av av_readdata readdata Output 8
add_interface_port av av_waitrequest_n waitrequest_n Output 1
add_interface_port av av_address address Input 8
set_interface_assignment av embeddedsw.configuration.isFlash 0
set_interface_assignment av embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment av embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment av embeddedsw.configuration.isPrintableDevice 0


# 
# connection point av_clk
# 
add_interface av_clk clock end
set_interface_property av_clk clockRate 0
set_interface_property av_clk ENABLED true
set_interface_property av_clk EXPORT_OF ""
set_interface_property av_clk PORT_NAME_MAP ""
set_interface_property av_clk SVD_ADDRESS_GROUP ""

add_interface_port av_clk av_clk clk Input 1


# 
# connection point av_reset
# 
add_interface av_reset reset end
set_interface_property av_reset associatedClock av_clk
set_interface_property av_reset synchronousEdges DEASSERT
set_interface_property av_reset ENABLED true
set_interface_property av_reset EXPORT_OF ""
set_interface_property av_reset PORT_NAME_MAP ""
set_interface_property av_reset SVD_ADDRESS_GROUP ""

add_interface_port av_reset av_reset reset Input 1


# 
# connection point can_clk_in
# 
add_interface can_clk_in clock end
set_interface_property can_clk_in clockRate 0
set_interface_property can_clk_in ENABLED true
set_interface_property can_clk_in EXPORT_OF ""
set_interface_property can_clk_in PORT_NAME_MAP ""
set_interface_property can_clk_in SVD_ADDRESS_GROUP ""

add_interface_port can_clk_in CAN_clk clk Input 1


# 
# connection point can_reset_in
# 
add_interface can_reset_in reset end
set_interface_property can_reset_in associatedClock av_clk
set_interface_property can_reset_in synchronousEdges DEASSERT
set_interface_property can_reset_in ENABLED true
set_interface_property can_reset_in EXPORT_OF ""
set_interface_property can_reset_in PORT_NAME_MAP ""
set_interface_property can_reset_in SVD_ADDRESS_GROUP ""

add_interface_port can_reset_in CAN_reset reset Input 1


# 
# connection point wire
# 
add_interface wire conduit end
set_interface_property wire associatedClock av_clk
set_interface_property wire associatedReset av_reset
set_interface_property wire ENABLED true
set_interface_property wire EXPORT_OF ""
set_interface_property wire PORT_NAME_MAP ""
set_interface_property wire SVD_ADDRESS_GROUP ""

add_interface_port wire CAN_rx export Input 1
add_interface_port wire CAN_tx export Output 1


# 
# connection point irq_n
# 
add_interface irq_n interrupt end
set_interface_property irq_n associatedAddressablePoint av
set_interface_property irq_n associatedClock av_clk
set_interface_property irq_n associatedReset av_reset
set_interface_property irq_n ENABLED true
set_interface_property irq_n EXPORT_OF ""
set_interface_property irq_n PORT_NAME_MAP ""
set_interface_property irq_n SVD_ADDRESS_GROUP ""

add_interface_port irq_n CAN_irq irq_n Output 1


# 
# connection point can_clk_out
# 
add_interface can_clk_out clock start
set_interface_property can_clk_out associatedDirectClock ""
set_interface_property can_clk_out clockRate 0
set_interface_property can_clk_out clockRateKnown false
set_interface_property can_clk_out ENABLED true
set_interface_property can_clk_out EXPORT_OF ""
set_interface_property can_clk_out PORT_NAME_MAP ""
set_interface_property can_clk_out SVD_ADDRESS_GROUP ""

add_interface_port can_clk_out CAN_clkout clk Output 1


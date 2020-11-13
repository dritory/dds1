set_property SRC_FILE_INFO {cfile:f:/Onedrive/NTNU/dds1/RSA_soc/boards/ip/rsa_soc_processing_system7_0_0/rsa_soc_processing_system7_0_0/rsa_soc_processing_system7_0_0_in_context.xdc rfile:../../../../boards/ip/rsa_soc_processing_system7_0_0/rsa_soc_processing_system7_0_0/rsa_soc_processing_system7_0_0_in_context.xdc id:1 order:EARLY scoped_inst:rsa_soc_i/processing_system7_0} [current_design]
set_property SRC_FILE_INFO {cfile:F:/Onedrive/NTNU/dds1/RSA_soc/boards/rsa_soc_ooc.xdc rfile:../../../../boards/rsa_soc_ooc.xdc id:2} [current_design]
current_instance rsa_soc_i/processing_system7_0
set_property src_info {type:SCOPED_XDC file:1 line:2 export:INPUT save:INPUT read:READ} [current_design]
create_clock -period 19.000 [get_ports {}]
current_instance
set_property src_info {type:XDC file:2 line:9 export:INPUT save:INPUT read:READ} [current_design]
create_clock -name processing_system7_0_FCLK_CLK0 -period 19 [get_pins processing_system7_0/FCLK_CLK0]

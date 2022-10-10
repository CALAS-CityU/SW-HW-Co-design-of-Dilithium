create_clock -period 6.0 -name clk -waveform {0.000 3.000} [get_ports clk]

set_property PACKAGE_PIN Y9 [get_ports clk]

set_property PACKAGE_PIN H15 [get_ports {start}];  # "XADC-GIO0"
set_property PACKAGE_PIN R15 [get_ports {sel}];  # "XADC-GIO1"
set_property PACKAGE_PIN K15 [get_ports {out_indicate}];  # "XADC-GIO2"
set_property PACKAGE_PIN J15 [get_ports {write_done}];  # "XADC-GIO3"


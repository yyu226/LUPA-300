gui_open_window Wave
gui_sg_create subpll_group
gui_list_add_group -id Wave.1 {subpll_group}
gui_sg_addsignal -group subpll_group {subpll_tb.test_phase}
gui_set_radix -radix {ascii} -signals {subpll_tb.test_phase}
gui_sg_addsignal -group subpll_group {{Input_clocks}} -divider
gui_sg_addsignal -group subpll_group {subpll_tb.CLK_IN1}
gui_sg_addsignal -group subpll_group {{Output_clocks}} -divider
gui_sg_addsignal -group subpll_group {subpll_tb.dut.clk}
gui_list_expand -id Wave.1 subpll_tb.dut.clk
gui_sg_addsignal -group subpll_group {{Counters}} -divider
gui_sg_addsignal -group subpll_group {subpll_tb.COUNT}
gui_sg_addsignal -group subpll_group {subpll_tb.dut.counter}
gui_list_expand -id Wave.1 subpll_tb.dut.counter
gui_zoom -window Wave.1 -full

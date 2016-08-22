gui_open_window Wave
gui_sg_create cmm_group
gui_list_add_group -id Wave.1 {cmm_group}
gui_sg_addsignal -group cmm_group {cmm_tb.test_phase}
gui_set_radix -radix {ascii} -signals {cmm_tb.test_phase}
gui_sg_addsignal -group cmm_group {{Input_clocks}} -divider
gui_sg_addsignal -group cmm_group {cmm_tb.CLK_IN1}
gui_sg_addsignal -group cmm_group {{Output_clocks}} -divider
gui_sg_addsignal -group cmm_group {cmm_tb.dut.clk}
gui_list_expand -id Wave.1 cmm_tb.dut.clk
gui_sg_addsignal -group cmm_group {{Counters}} -divider
gui_sg_addsignal -group cmm_group {cmm_tb.COUNT}
gui_sg_addsignal -group cmm_group {cmm_tb.dut.counter}
gui_list_expand -id Wave.1 cmm_tb.dut.counter
gui_zoom -window Wave.1 -full

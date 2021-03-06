transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/Sem\ 1/ECE4063/ECE4063-Project/CameraLCD {/home/xavieran/BEngBSc/YEAR 5/Sem 1/ECE4063/ECE4063-Project/CameraLCD/CumulativeHistogram.v}

vlog -vlog01compat -work work +incdir+/home/xavieran/BEngBSc/YEAR\ 5/Sem\ 1/ECE4063/ECE4063-Project/CameraLCD {/home/xavieran/BEngBSc/YEAR 5/Sem 1/ECE4063/ECE4063-Project/CameraLCD/CumulativeHistogram_Testbench.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneii_ver -L rtl_work -L work -voptargs="+acc"  CumulativeHistogram_Testbench

add wave *
view structure
view signals
run -all

transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/segura/Documents/Master/1r-Quadrimestre/PA/mipsproc/verilog_test {/home/segura/Documents/Master/1r-Quadrimestre/PA/mipsproc/verilog_test/VerilogTest.v}


source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh;
rm -rfv `ls |grep -v ".*\.sv\|.*\.sh"`;

vcs -Mupdate test_bench.sv  -o salida -full64 -debug_all -sverilog -kdb -l log_test -ntb_opts uvm-1.2 +lint=TFIPC-L -cm line+tgl+cond+fsm+branch+assert +UVM_VERBOSITY=UVM_HIGH;

./salida +UVM_TIMEOUT=100000 -cm line+tgl+cond+fsm+branch+assert +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=test_FP_Multiplier +ntb_random_seed=1 > deleteme_log_1;
./salida +UVM_TIMEOUT=100000 -cm line+tgl+cond+fsm+branch+assert +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=test_FP_Multiplier_rmode_000 +ntb_random_seed=1 > deleteme_log_000;
./salida +UVM_TIMEOUT=100000 -cm line+tgl+cond+fsm+branch+assert +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=test_FP_Multiplier_rmode_001 +ntb_random_seed=2 > deleteme_log_001;
./salida +UVM_TIMEOUT=100000 -cm line+tgl+cond+fsm+branch+assert +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=test_FP_Multiplier_rmode_010 +ntb_random_seed=3 > deleteme_log_010;
./salida +UVM_TIMEOUT=100000 -cm line+tgl+cond+fsm+branch+assert +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=test_FP_Multiplier_rmode_011 +ntb_random_seed=4 > deleteme_log_011;
./salida +UVM_TIMEOUT=100000 -cm line+tgl+cond+fsm+branch+assert +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=test_FP_Multiplier_rmode_100 +ntb_random_seed=5 > deleteme_log_100;
verdi -cov -covdir salida.vdb & -gui;

#./salida -cm line+tgl+cond+fsm+branch+assert;
#dve -full64 -covdir salida.vdb &

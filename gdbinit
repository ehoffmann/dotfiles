set confirm off
set pagination off
set print pretty on
set print elements 0
# set print array on
# set disassemble-next-line on

set history expansion on
set history save on
set history filename ~/.gdb_history
set history size 10000

handle SIGPIPE nostop noprint pass
handle SIGABRT stop print nopass
set environment ASAN_OPTIONS abort_on_error=1:halt_on_error=1:disable_coredump=0:fast_unwind_on_malloc=0:detect_leaks=0

define parr
  print *$arg0@$arg1
end

define darr
  display *$arg0@$arg1
end

define hook-quit
  save breakpoints .gdb_breakpoints
end

define hookpost-file
  source .gdb_breakpoints
end

define brestore
  source .gdb_breakpoints
end

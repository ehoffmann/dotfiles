set confirm off
set pagination off
set print pretty on
set print elements 0
set disassemble-next-line on
handle SIGPIPE nostop noprint pass
handle SIGABRT stop print nopass
set environment ASAN_OPTIONS abort_on_error=1:halt_on_error=1:disable_coredump=0:fast_unwind_on_malloc=0:detect_leaks=0

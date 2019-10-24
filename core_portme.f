
VALIDATION_RUN [if]
   $15 $34  \ seed1 = 0x3415
   $15 $34  \ seed2 = 0x3415
   $66 $00  \ seed3 = 0x0066
[then]
PERFORMANCE_RUN [if]
   $00 $00  \ seed1 = 0x0000
   $00 $00  \ seed2 = 0x0000
   $66 $00  \ seed3 = 0x0066
[then]
PROFILE_RUN [if]
   $08 $00  \ seed1 = 0x0008
   $08 $00  \ seed2 = 0x0008
   $08 $00  \ seed3 = 0x0008
[then]
$00 $00  \ seed4 = 0x0000  ITERATIONS
$00 $00  \ seed5 = 0x0000
#5 array_s32_init get_seed_32

2variable start_time_var
2variable stop_time_var

\ Function : start_time
\	This function will be called right before starting the timed portion of the benchmark.
: start_time  ( -- )  \ void start_time(void)
   utime start_time_var 2! ;

\ Function : stop_time
\ This function will be called right after ending the timed portion of the benchmark.
: stop_time  ( -- )  \ void stop_time(void)
   utime stop_time_var 2! ;

\ Function : get_time
\	Return an abstract "ticks" number that signifies time on the system.
: get_time  ( -- ud )  \ CORE_TICKS get_time(void)
   stop_time_var 2@ start_time_var 2@ d- ;

\ Function : time_in_secs
\	Convert the value returned by get_time to seconds.
: time_in_secs  ( ud -- u )  \ secs_ret time_in_secs(CORE_TICKS ticks)
   #1000000 um/mod nip ;

\ ee_u8  -> char
\ ee_s16 -> n
\ ee_u16 -> u
\ ee_s32 -> d
\ ee_u32 -> ud

VALIDATION_RUN PERFORMANCE_RUN or PROFILE_RUN or invert [if]
   TOTAL_DATA_SIZE #1200 = [if]
      true to PROFILE_RUN
   [else]
      TOTAL_DATA_SIZE #2000 = [if]
         true to PERFORMANCE_RUN
      [else]
         true to VALIDATION_RUN
      [then]
   [then]
[then]
      

VALIDATION_RUN [if]
   $3415 $0000  \ seed1 = 0x3415
   $3415 $0000  \ seed2 = 0x3415
   $0066 $0000  \ seed3 = 0x0066
[then]
PERFORMANCE_RUN [if]
   $0000 $0000  \ seed1 = 0x0000
   $0000 $0000  \ seed2 = 0x0000
   $0066 $0000  \ seed3 = 0x0066
[then]
PROFILE_RUN [if]
   $0008 $0000  \ seed1 = 0x0008
   $0008 $0000  \ seed2 = 0x0008
   $0008 $0000  \ seed3 = 0x0008
[then]
$0000 $0000  \ seed4 = 0x0000  ITERATIONS
$0000 $0000  \ seed5 = 0x0000
2array_init get_seed_32

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

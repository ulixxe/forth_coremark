
false value VALIDATION_RUN
true value PERFORMANCE_RUN
false value PROFILE_RUN

#2 #1000 * constant TOTAL_DATA_SIZE

\ list data structures
\ typedef struct list_data_s {
\ 	ee_s16 data16;
\ 	ee_s16 idx;
\ } list_data;

\ typedef struct list_head_s {
\ 	struct list_head_s *next;
\ 	struct list_data_s *info;
\ } list_head;

s" ./core_util.f" included
s" ./core_portme.f" included

#5 array list_known_crc
$d4b0 $3340 $6a79 $e714 $e3c1 array_init list_known_crc
#5 array matrix_known_crc
$be52 $1199 $5608 $1fd7 $0747 array_init matrix_known_crc
#5 array state_known_crc
$5e47 $39bf $e5a4 $8e3a $8d84 array_init state_known_crc

$1 constant ID_LIST
$2 constant ID_MATRIX
$4 constant ID_STATE
$7 constant ALL_ALGORITHMS_MASK
#3 constant NUM_ALGORITHMS

0 get_seed_32 d>s value seed1
1 get_seed_32 d>s value seed2
2 get_seed_32 d>s value seed3
3 get_seed_32 2value iterations
4 get_seed_32 d>s value execs
0 value err

: list_elems  ( u1 -- u2 )
   \	ee_u32 per_item=16+sizeof(struct list_data_s);
   #16 #2 #2 + +  \ per_list_item

   \ #list elements = (TOTAL_DATA_SIZE/num_algorithms/per_item)-2
   \   where per_item = 16+sizeof(struct list_data_s)
   \     here per_item = 2 * cell + 2 * cell = 4 cells

   \ TOTAL_LIST_DATA_SIZE = #list elements * 4 cells

   / 2 - ;  \ #list elements

\ calculate matrix dimension to fit in allotted memory size
: matrix_size  ( u1 -- u2 )
   0
   begin  ( blksize i )
      1+ over
      over dup * 2 * 4 *  ( blksize j )
      > while
   repeat
   1- nip ;

: matrix_blksize  ( u1 -- u2 )  \ N
   dup * 4 * cells ;

: blksizes  ( u1 -- u2 u3 u4 )  \ execs  -- list matrix state
   dup 0= if drop ALL_ALGORITHMS_MASK then
   0
   NUM_ALGORITHMS 0 do
      over 1 i lshift and if 1+ then
   loop

   TOTAL_DATA_SIZE swap /  \ data size allocated for each algorithm

   over ID_STATE and if
      dup  \ state mem size
   else
      0
   then
   >r
   over ID_MATRIX and if
      dup matrix_size  \ N
   else
      0
   then
   >r
   swap ID_LIST and if
      list_elems
      4 * cells  \ list mem size
   else
      0
   then
   r> r> ;

execs blksizes

rot  \ matrix_size state_size list_size

s" ./core_list_join.f" included

create list_head
dup cell+ allot  \ reserve memory for list head and list data
list_head seed1 core_list_init

swap  \ state_size matrix_size

s" ./core_matrix.f" included

create matrix_data
dup matrix_blksize 4 cells + allot
matrix_data seed1 core_init_matrix

s" ./core_state.f" included

create state_data
dup cell+ allot
state_data seed1 core_init_state


: debug  ( -- )
   cr list_head .list cr
   cr ." Matrix A:"
   matrix_data @
   matrix_data cell+ @
   cr .matrix
   cr ." Matrix B:"
   matrix_data @
   matrix_data cell+ cell+ @
   cr .matrix
   cr ." State Input:"
   state_data cell+
   state_data @
   cr type
;

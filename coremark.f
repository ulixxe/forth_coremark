
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

variable seed1
variable seed2
variable seed3
2variable iterations
variable execs
variable err
variable crc
variable crclist
variable crcmatrix
variable crcstate
0 get_seed_32 d>s seed1 !
1 get_seed_32 d>s seed2 !
2 get_seed_32 d>s seed3 !
3 get_seed_32 iterations 2!
4 get_seed_32 d>s execs !

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

execs @ blksizes  \ list_size matrix_size state_size

s" ./core_state.f" included
create state_data
dup cell+ allot
state_data seed1 @ core_init_state

s" ./core_matrix.f" included
create matrix_data
dup matrix_blksize 4 cells + allot
matrix_data seed1 @ core_init_matrix

create list_head
dup cell+ allot  \ reserve memory for list head and list data
s" ./core_list_join.f" included
list_head seed1 @ core_list_init

: n  ( -- u )
   matrix_data p->n ;
: a  ( -- a-addr )
   matrix_data p->a ;
: b  ( -- a-addr )
   matrix_data p->b ;
: c  ( -- a-addr )
   matrix_data p->c ;
: a.matrix  ( -- )
   cr ." Matrix A:"
   n a
   cr s16.matrix ;
: b.matrix  ( -- )
   cr ." Matrix B:"
   n b
   cr s16.matrix ;
: c.matrix  ( -- )
   cr ." Matrix C:"
   n c
   cr s32.matrix ;
: debug  ( -- )
   cr list_head .list cr
   a.matrix
   b.matrix
   cr ." State Input:"
   state_data cell+
   state_data @
   cr type
;

: iterate  ( ud -- )  \ iterations
   0 crc !
   0 crclist !
   0 crcmatrix !
   0 crcstate !
   0 >r  \ iterations R: first
   begin
      1 0 d-
      2dup d0<
      invert
   while
         #1 core_bench_list
         crc @ crcu16
         crc !
         #-1 core_bench_list
         crc @ crcu16
         crc !
         r@ if
         else
            crc @ crclist !
            r> drop
            1 >r
         then
   repeat
   r> drop 2drop ;

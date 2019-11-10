
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

\ calculate matrix dimension to fit in allotted memory size
: matrix_size  ( u1 -- u2 )
   0
   begin  ( blksize i )
      1+ over
      over dup * 2 * 4 *  ( blksize j )
      > while
   repeat
   1- nip ;

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

0 value #algorithms
0 value list_elems
0 value list_blksize
0 value N
0 value matrix_blksize
0 value state_blksize

: init  ( -- )
   execs 0= if ALL_ALGORITHMS_MASK to execs then
   0
   NUM_ALGORITHMS 0 do
      1 i lshift execs and if 1+ then
   loop
   to #algorithms

   TOTAL_DATA_SIZE #algorithms /  \ data size allocated for each algorithm

   execs ID_LIST and if
      dup
      \	ee_u32 per_item=16+sizeof(struct list_data_s);
      #16 #2 #2 + +  \ per_list_item

      \ #list elements = (TOTAL_DATA_SIZE/num_algorithms/per_item)-2
      \   where per_item = 16+sizeof(struct list_data_s)
      \     here per_item = 2 * cell + 2 * cell = 4 cells

      \ TOTAL_LIST_DATA_SIZE = #list elements * 4 cells

      / 2 - to list_elems \ #list elements
      list_elems 4 * cells to list_blksize
   then

   execs ID_MATRIX and if
      dup matrix_size to N
      N dup * 4 * cells to matrix_blksize
   then

   execs ID_STATE and if
      dup to state_blksize
   then
   drop
;

init

#4 array memblock_size
list_blksize matrix_blksize + state_blksize +
list_blksize matrix_blksize state_blksize array_init memblock_size
create memblock 0 memblock_size allot
#4 array memblock_addr
memblock dup dup list_blksize + dup matrix_blksize + array_init memblock_addr



\ s" ./core_list_join.f" included


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

$1 constant ID_LIST
$2 constant ID_MATRIX
$4 constant ID_STATE
$7 constant ALL_ALGORITHMS_MASK
#3 constant NUM_ALGORITHMS

#3 value #algorithms

TOTAL_DATA_SIZE #algorithms /  \ data size allocated for each algorithm

dup
\	ee_u32 per_item=16+sizeof(struct list_data_s);
#16 #2 #2 + +  \ per_list_item

\ #list elements = (TOTAL_DATA_SIZE/num_algorithms/per_item)-2
\   where per_item = 16+sizeof(struct list_data_s)
\     here per_item = 2 * cell + 2 * cell = 4 cells

\ TOTAL_LIST_DATA_SIZE = #list elements * 4 cells

/ 2 - constant list_elems \ #list elements
list_elems 4 * cells constant list_blksize

\ calculate matrix dimension to fit in allotted memory size
: matrix_size  ( u1 -- u2 )
   0
   begin  ( blksize i )
      1+ over
      over dup * 2 * 4 *  ( blksize j )
      > while
   repeat
   1- nip ;

dup matrix_size  constant N
N dup * 4 * cells constant matrix_blksize

constant state_blksize

create memblock list_blksize matrix_blksize + state_blksize + allot


\ s" ./core_list_join.f" included

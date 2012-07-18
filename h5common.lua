local ffi = require("ffi")
--local hdf5 = ffi.load("hdf5")
local modname = ...
local H5 = {} --Exported functions, public interface
local h5 = {} --internal functions, h5-specific
_G[modname] = H5

package.loaded[modname] = H5

ffi.cdef[[
typedef int hid_t;
typedef int herr_t;

/*TODO: perhaps, one day, read it from the system*/
typedef unsigned int time_t; 
/*TODO could lead to weird problems*/
typedef uint64_t haddr_t;

/* Common iteration orders */
typedef enum {
    H5_ITER_UNKNOWN = -1,       /* Unknown order */
    H5_ITER_INC,                /* Increasing order */
    H5_ITER_DEC,                /* Decreasing order */
    H5_ITER_NATIVE,             /* No particular order, whatever is fastest */
    H5_ITER_N		        /* Number of iteration orders */
} H5_iter_order_t;


/*
 * The types of indices on links in groups/attributes on objects.
 * Primarily used for "<do> <foo> by index" routines and for iterating over
 * links in groups/attributes on objects.
 */
typedef enum H5_index_t {
    H5_INDEX_UNKNOWN = -1,	/* Unknown index type			*/
    H5_INDEX_NAME,		/* Index on names 			*/
    H5_INDEX_CRT_ORDER,		/* Index on creation order 		*/
    H5_INDEX_N			/* Number of indices defined 		*/
} H5_index_t;


]]
--H5S
ffi.cdef[[
typedef unsigned long long hsize_t;
typedef signed long long hssize_t;
]]

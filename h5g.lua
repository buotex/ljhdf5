ffi = require "ffi"
local ffi = require("ffi")
local hdf5 = ffi.load("hdf5")


local h5common=   require("h5common")

local modname = ...
local H5O = {} --Exported functions, public interface
local h5o = {} --internal functions, h5-specific
_G[modname] = H5O

package.loaded[modname] = H5O

ffi.cdef[[


typedef enum H5O_type_t {
    H5O_TYPE_UNKNOWN = -1,      /* Unknown object type                              */
    H5O_TYPE_GROUP,             /* Object is a group                                */
    H5O_TYPE_DATASET,           /* Object is a dataset                              */
    H5O_TYPE_NAMED_DATATYPE,    /* Object is a committed (named) datatype           */
    H5O_TYPE_NTYPES             /* Number of different object types (must be last!) */
} H5O_type_t;

typedef struct H5_ih_info_t {
    hsize_t     index_size;     /* btree and/or list */
    hsize_t     heap_size;
} H5_ih_info_t;

typedef struct H5O_hdr_info_t {
    unsigned version;           /* Version number of header format in file  */
    unsigned nmesgs;            /* Number of object header messages         */
    unsigned nchunks;           /* Number of object header chunks           */
    unsigned flags;             /* Object header status flags               */
    struct {
        hsize_t total;          /* Total space for storing object header in */ 
                                /*   file                                   */
        hsize_t meta;           /* Space within header for object header    */
                                /*   metadata information                   */
        hsize_t mesg;           /* Space within header for actual message   */
                                /*   information                            */
        hsize_t free;           /* Free space within object header          */
    } space;
    struct {
        uint64_t present;       /* Flags to indicate presence of message    */
                                /*   type in header                         */
        uint64_t shared;        /* Flags to indicate message type is        */
                                /*   shared in header                       */
    } mesg;
} H5O_hdr_info_t;

typedef struct H5O_info_t {
    unsigned long 	fileno;		/* File number that object is located in */
    haddr_t 		addr;		/* Object address in file	*/
    H5O_type_t 		type;		/* Basic object type (group, dataset, etc.) */
    unsigned 		rc;		/* Reference count of object    */
    time_t		atime;		/* Access time			*/
    time_t		mtime;		/* Modification time		*/
    time_t		ctime;		/* Change time			*/
    time_t		btime;		/* Birth time			*/
    hsize_t 		num_attrs;	/* # of attributes attached to object */
    H5O_hdr_info_t      hdr;            /* Object header information */
    /* Extra metadata storage for obj & attributes */
    struct {
        H5_ih_info_t   obj;             /* v1/v2 B-tree & local/fractal heap for groups, B-tree for chunked datasets */
        H5_ih_info_t   attr;            /* v2 B-tree & heap for attributes */
    } meta_size;
} H5O_info_t;








]]

--ffi.cdef[[
--typedef enum H5G_obj_t {
--    H5G_UNKNOWN = -1,		/* Unknown object type		*/
--    H5G_GROUP,		        /* Object is a group		*/
--    H5G_DATASET,		/* Object is a dataset		*/
--    H5G_TYPE,			/* Object is a named data type	*/
--    H5G_LINK,		        /* Object is a symbolic link	*/
--    H5G_UDLINK,		        /* Object is a user-defined link */
--    H5G_RESERVED_5,		/* Reserved for future use	*/
--    H5G_RESERVED_6,		/* Reserved for future use	*/
--    H5G_RESERVED_7		/* Reserved for future use	*/
--} H5G_obj_t;
--
--
--typedef struct H5G_stat_t {
--    unsigned long 	fileno[2];	/*file number			*/
--    unsigned long 	objno[2];	/*object number			*/
--    unsigned 		nlink;		/*number of hard links to object*/
--    H5G_obj_t 		type;		/*basic object type		*/
--    time_t		mtime;		/*modification time		*/
--    size_t		linklen;	/*symbolic link value length	*/
--    H5O_stat_t          ohdr;           /* Object header information    */
--} H5G_stat_t;
--]]
--ffi.cdef[[
--typedef int (__stdcall *H5G_iterate_t) 
--(hid_t group_id, const char * member_name, void *operator_data);
--int H5Giterate(hid_t loc_id, const char *name, int *idx, H5G_iterate_t operator, void *operator_data );
--]]
--
--h5g.obj_t = {
--["H5G_GROUP"] =  "group",
--["H5G_DATASET"]= "dataset",
--["H5G_TYPE"]= "datatype"
--}
h5o.obj_t = {
[ffi.C.H5O_TYPE_GROUP] =  "(Group)",
[ffi.C.H5O_TYPE_DATASET]= "(Dataset)",
[ffi.C.H5O_TYPE_NAMED_DATATYPE]= "(Datatype)"
}

ffi.cdef[[
typedef herr_t (__stdcall *H5O_iterate_t)( hid_t o_id, const char *name, const H5O_info_t *object_info, void *op_data);
herr_t H5Ovisit( hid_t object_id, H5_index_t index_type, H5_iter_order_t order, H5O_iterate_t op, void *op_data );
]]


H5O.recursive_iteration = function(object_id, member_name, object_info, operator_data)
  io.write("/")
  if member_name[0] == '.' then
    print("  (Group)")
  else
    print(string.format("%s %s", ffi.string(member_name), h5o.obj_t[object_info.type]))
  end
  return 0
end


H5O.printSets = function(handle, index, operator_data)
  if not operator_data then
    operator_data = ffi.cast("void *", 0)
  end
  local index = ffi.new("H5_index_t","H5_INDEX_NAME")
  local order = ffi.new("H5_iter_order_t", "H5_ITER_NATIVE")
  local operator = ffi.cast("H5O_iterate_t", H5O.recursive_iteration)
  --hdf5.H5Giterate(handle.id, ffi.cast("const char *", name), idx, operator, operator_data)
  hdf5.H5Ovisit(handle.id, index, order, operator, operator_data)
  return 0
end

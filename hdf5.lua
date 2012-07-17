local ffi = require("ffi")
local hdf5 = ffi.load("hdf5")


local ffi     =   require("ffi")
local array   =   require("ljarray.array")


local modname = ...
local H5 = {}
_G[modname] = H5
package.loaded[modname] = H5
H5.H5F_ACC_RDONLY = 0
H5.H5T_NATIVE_INT = 0
local mt = {}
mt.__index = hdf5
setmetatable(H5, mt)


ffi.cdef[[

typedef enum H5T_class_t {
    H5T_NO_CLASS         = -1,  /*error                                      */
    H5T_INTEGER          = 0,   /*integer types                              */
    H5T_FLOAT            = 1,   /*floating-point types                       */
    H5T_TIME             = 2,   /*date and time types                        */
    H5T_STRING           = 3,   /*character string types                     */
    H5T_BITFIELD         = 4,   /*bit field types                            */
    H5T_OPAQUE           = 5,   /*opaque types                               */
    H5T_COMPOUND         = 6,   /*compound types                             */
    H5T_REFERENCE        = 7,   /*reference types                            */
    H5T_ENUM		 = 8,	/*enumeration types                          */
    H5T_VLEN		 = 9,	/*Variable-Length types                      */
    H5T_ARRAY	         = 10,	/*Array types                                */

    H5T_NCLASSES                /*this must be last                          */
} H5T_class_t;
typedef int hid_t;
typedef int herr_t;

]]
H5.T_INTEGER = {
[1] = array.uint8,
[2] = array.uint16,
[4] = array.uint32,
[8] = array.uint64
}
H5.T_FLOAT = {
[4] = array.float32,
[8] = array.float64
}
H5.F_ACC={
["RDONLY"]  = 0,
["RDWR"]    = 1,
["TRUNC"]   = 2
}

H5.H5T_CLASSES = {
[ffi.C.H5T_INTEGER] = H5.T_INTEGER,
[ffi.C.H5T_FLOAT] = H5.T_FLOAT
}


ffi.cdef[[
hid_t H5Fopen(const char * name, unsigned flags, hid_t fapl_id);
herr_t H5Fclose(hid_t file_id);
hid_t H5Dopen2(hid_t loc_id, const char *name);
hid_t H5Dclose(hid_t dataset_id);
hid_t H5Dget_type(hid_t dataset_id);
H5T_class_t H5Tget_class(hid_t tid);
herr_t H5Dread(hid_t dataset_id, hid_t mem_type_id, hid_t mem_space_id, hid_t file_space_id, hid_t xfer_plist_id, void * buf);
size_t H5Tget_size(hid_t datatype);
]]

function H5.rH5data(filename, datasetname, slicing, verbose) 
  local flags = H5.F_ACC["RDWR"]
  local fapl_id = 0
  local filehandle = H5.H5Fopen(filename, flags, fapl_id)
  local datahandle = H5.H5Dopen2(filehandle, datasetname)
  local datatype = H5.H5Dget_type(datahandle)
  local dataclass = H5.H5Tget_class(datatype)
  local typesize = H5.H5Tget_size(datatype)
  local buf = array.create(slicing, H5.H5T_CLASSES[dataclass][tonumber(typesize)])
  local success = H5.H5Dread(datahandle, datatype, 0,0,0, buf.data) --TODO
  H5.H5Dclose(datahandle)
  H5.H5Fclose(filehandle)
  return success, buf
end



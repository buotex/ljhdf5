local ffi = require("ffi")
local hdf5 = ffi.load("hdf5")


local ffi     =   require("ffi")
local array   =   require("ljarray.array")
local h5common=   require("h5common")


local modname = ...
local H5 = {} --Exported functions, public interface
local h5 = {} --internal functions, h5-specific
_G[modname] = H5

package.loaded[modname] = H5

--setmetatable(H5, mt)


--general

local h5g     =   require("h5g")
--[[
for k,v in pairs(h5g) do
  H5[k] = h5g[k]
end
]]--
--H5F

h5.F_ACC={
  ["RDONLY"]  = 0,
  ["RDWR"]    = 1,
  ["TRUNC"]   = 2
}
ffi.cdef[[
hid_t H5Fopen(const char * name, unsigned flags, hid_t fapl_id);
herr_t H5Fclose(hid_t file_id);
]]

h5.FileHandle = ffi.metatype("struct {hid_t id;}", {__gc = function(self) hdf5.H5Fclose(self.id) end} )

--H5P

h5.P_DEFINES = {
  ["H5P_DEFAULT"] = 0
}

--H5T

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


/* Types of integer sign schemes */
typedef enum H5T_sign_t {
    H5T_SGN_ERROR        = -1,  /*error                                      */
    H5T_SGN_NONE         = 0,   /*this is an unsigned type                   */
    H5T_SGN_2            = 1,   /*two's complement                           */

    H5T_NSGN             = 2    /*this must be last!                         */
} H5T_sign_t;
]]

ffi.cdef[[
size_t H5Tget_size(hid_t dtype_id);
H5T_class_t H5Tget_class(hid_t dtype_id);
H5T_sign_t H5Tget_sign(hid_t dtype_id);
]]

h5.T_uint_table = 
{
  [1] = array.uint8,
  [2] = array.uint16,
  [4] = array.uint32,
  [8] = array.uint64
}
h5.T_int_table = 
{
  [1] = array.int8,
  [2] = array.int16,
  [4] = array.int32,
  [8] = array.int64
}
h5.T_INTEGER = function(type_id)
  local type_size = hdf5.H5Tget_size(type_id)
  local type_sign = hdf5.H5Tget_sign(type_id)
  print(type_size)
  if type_sign == hdf5.H5T_SGN_NONE then
    return h5.T_uint_table[tonumber(type_size)]
  elseif type_sign == hdf5.H5T_SGN_2 then
    return h5.T_int_table[tonumber(type_size)]
  else 
    error("NYI: datatype == integer but sign is neither uint nor int")
  end
  error("NYI: datatype == integer but sign is neither uint nor int")
  
  return 
end


h5.T_float_table = {
  [4] = array.float32,
  [8] = array.float64
}

h5.T_FLOAT = function(type_id)
  local type_size = ffi.C.H5Tget_size(type_id)
  return float_table[tonumber(type_size)]
end


h5.T_CLASSES = {
  [ffi.C.H5T_INTEGER] = h5.T_INTEGER,
  [ffi.C.H5T_FLOAT] = h5.T_FLOAT
}


h5.getDtype = function(data_type)
  print("bla")
  local type_id = hdf5.H5Tget_class(data_type)
  local type_class = h5.T_CLASSES[type_id]
  return type_class(data_type)
end

--H5S 

ffi.cdef[[
typedef enum H5S_seloper_t {
  H5S_SELECT_NOOP      = -1,  /* error                                     */
  H5S_SELECT_SET       = 0,   /* Select "set" operation 		     */
  H5S_SELECT_OR,              /* Binary "or" operation for hyperslabs
  * (add new selection to existing selection)
  * Original region:  AAAAAAAAAA
  * New region:             BBBBBBBBBB
  * A or B:           CCCCCCCCCCCCCCCC
  */
  H5S_SELECT_AND,             /* Binary "and" operation for hyperslabs
  * (only leave overlapped regions in selection)
  * Original region:  AAAAAAAAAA
  * New region:             BBBBBBBBBB
  * A and B:                CCCC
  */
  H5S_SELECT_XOR,             /* Binary "xor" operation for hyperslabs
  * (only leave non-overlapped regions in selection)
  * Original region:  AAAAAAAAAA
  * New region:             BBBBBBBBBB
  * A xor B:          CCCCCC    CCCCCC
  */
  H5S_SELECT_NOTB,            /* Binary "not" operation for hyperslabs
  * (only leave non-overlapped regions in original selection)
  * Original region:  AAAAAAAAAA
  * New region:             BBBBBBBBBB
  * A not B:          CCCCCC
  */
  H5S_SELECT_NOTA,            /* Binary "not" operation for hyperslabs
  * (only leave non-overlapped regions in new selection)
  * Original region:  AAAAAAAAAA
  * New region:             BBBBBBBBBB
  * B not A:                    CCCCCC
  */
  H5S_SELECT_APPEND,          /* Append elements to end of point selection */
  H5S_SELECT_PREPEND,         /* Prepend elements to beginning of point selection */
  H5S_SELECT_INVALID          /* Invalid upper bound on selection operations */
} H5S_seloper_t;
]]


ffi.cdef[[
herr_t H5Sclose(hid_t space_id);
int H5Sget_simple_extent_ndims( hid_t space_id );
int H5Sget_simple_extent_dims(hid_t space_id, hsize_t *dims, hsize_t *maxdims );
hid_t H5Screate_simple( int rank, const hsize_t * current_dims, const hsize_t * maximum_dims );
herr_t H5Sselect_hyperslab(hid_t space_id, H5S_seloper_t op, const hsize_t *start, const hsize_t *stride, const hsize_t *count, const hsize_t *block );
]]

h5.SpaceHandle = ffi.metatype("struct {hid_t id;}", {__gc = function(self) hdf5.H5Sclose(self.id) end} )

h5.S_space_id = {
  ["H5S_ALL"] = 0,
  ["H5S_UNLIMITED"] = tonumber(ffi.new("hsize_t", tonumber(ffi.new("hssize_t", -1))))
}
h5.get_space_extents = function(space_id)

  local rank = hdf5.H5Sget_simple_extent_ndims(space_id)
  local dims = ffi.new("hsize_t[?]", rank)
  --local maxdims = ffi.new("hsize_t[?]", rank)
  hdf5.H5Sget_simple_extent_dims(space_id, dims, ffi.cast("void *", 0))
  return rank, dims
end
--[[
local createSpaceInformation = function(range, max)

if not max then
local dims = 
end
return dims, maxdims
end
]]--


h5.convertSlicing = function(slicing)
  local offset = {}
  local shape = {}

  for i,v in ipairs(slicing) do
    if type(v) == "number" then
      offset[i] = 0
      shape[i] = v
    elseif type(v) == "table" then
      if #v == 2 then
        offset[i] = v[1]
        shape[i] = v[2] - v[1]
      else
        error("NYI: can't handle shape: " .. v)
      end
    else
      error("NYI: can't handle shape: " .. v)
    end
  end
  return offset,shape
end


--H5D

ffi.cdef[[
hid_t H5Dopen2(hid_t loc_id, const char *name);
hid_t H5Dclose(hid_t dataset_id);
hid_t H5Dget_type(hid_t dataset_id);
hid_t H5Dget_space(hid_t dataset_id);
herr_t H5Dread(hid_t dataset_id, hid_t mem_type_id, hid_t mem_space_id, hid_t file_space_id, hid_t xfer_plist_id, void * buf);
]]


h5.DataHandle = ffi.metatype("struct {hid_t id;}", {__gc = function(self) hdf5.H5Dclose(self.id) end} )


h5.getSlice = function(datahandle, slicing, dataset_dtype, array_dtype) 
  local offset,shape = h5.convertSlicing(slicing)
  local buf       =   array.create(shape, array_dtype)
  --xfer_plist_id --TODO
  local xfer_plist_id = h5.P_DEFINES["H5P_DEFAULT"] --TODO !/
  local dataspace     = h5.SpaceHandle(hdf5.H5Dget_space(datahandle.id))
  local rank,dims     = h5.get_space_extents(dataspace.id)
  local offset_out    = ffi.new("const hsize_t[?]", #offset, offset)
  local count_out     = ffi.new("const hsize_t[?]", #shape, shape)
  local status        = hdf5.H5Sselect_hyperslab(dataspace.id, ffi.C.H5S_SELECT_SET, offset_out, ffi.cast("void *",0), count_out, ffi.cast("void *",0) )
  --local file_space_id = hdf5.H5Screate_simple(#range, ffi.new("const hsize_t[?]",range), ffi.cast("const hsize_t *", 0))
  local array_element_type = dataset_dtype --TODO, offer other possibilities?
  local memspace      = h5.SpaceHandle(hdf5.H5Screate_simple(#shape, count_out, ffi.cast("void *", 0)))
  --print(datahandle.id, array_dtype, memspace.id, dataspace.id, xfer_plist_id, buf)
  local success       = hdf5.H5Dread(datahandle.id, array_element_type, memspace.id, dataspace.id, xfer_plist_id, buf.data) --TODO

  return success, buf
end



H5.rH5data = function(filename, datasetname, slicing, verbose) 
  local buf = nil
  local success = nil
  do
    local flags     =   h5.F_ACC["RDWR"]
    local fapl_id   =   0
    local filehandle=   h5.FileHandle(hdf5.H5Fopen(filename, flags, fapl_id))

    local datahandle=   h5.DataHandle(hdf5.H5Dopen2(filehandle.id, datasetname))
    local dataset_dtype= hdf5.H5Dget_type(datahandle.id)

    local array_dtype = h5.getDtype(dataset_dtype)
    print(array_dtype, "blub")
    success,buf = h5.getSlice(datahandle, slicing, dataset_dtype, array_dtype)
    print(success, "READING")
    if not success then
      print("Error reading slice, further proceedings NYI")
      --error("Something broke while reading the slice")
    end
  end
  collectgarbage()

  return buf, success
end


H5.printSets = function(filename, index, operator_data) 
  do
    if not index then
      index = 0
    end
    local flags     =   h5.F_ACC["RDONLY"]
    local fapl_id   =   0
    local filehandle=   h5.FileHandle(hdf5.H5Fopen(filename, flags, fapl_id))
    local success = h5g.printSets(filehandle, index, operator_data)
  end
  collectgarbage()
end


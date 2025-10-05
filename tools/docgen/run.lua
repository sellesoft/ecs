local lake = require "lake"
local o = lake.obj
local List = require "iro.List"
local Process = require "iro.os.Process"
local sbuf = require "string.buffer"
local lpp = require "lake.driver.lpp"

---@class tools.docgen.Params
---
---@field build_dir string
---
---@field lpp_params lake.obj.Lpp.PreprocessParams
---
---@field cpp_params lake.obj.Cpp.CompileParams
---
---@field cwd string

local function run_gen(file, ofile, meta_args, lpp_params)
  ---@type lake.driver.lpp.Params
  local lpp_args = 
  {
    input_path = "tools/docgen/"..file..".lpp",
    output_path = ofile,
    cpath_dirs = { "lib" },
    require_dirs = { "src" },
    import_dirs = { "src" },
    meta_args =  List
    { 
      lpp_params.meta_args, 
      List(meta_args),
    }:flatten()
  }

  local time, result = lake.utils.timed(function()
    return lake.async.run(lpp(lpp_args))
  end)

  if result.exit_code ~= 0 then
    lake.flair.writeFailure(ofile)
    io.write(result.output)
    return false
  else
    lake.flair.writeSuccessOnlyOutput(
      ofile, time:pretty())
    return true
  end
end

local processed_types = {}
local function run_type_gen(ofile, header, type, lpp_params)
  if processed_types[type] then
    return true
  end

  processed_types[type] = true

  return run_gen("gen_type_note", ofile, 
  {
    "--header="..header,
    "--type="..type,
  }, lpp_params)
end

local processed_ns = {}
local function run_ns_gen(ofile, header, ns, lpp_params)
  if processed_ns[ns] then
    return true
  end

  processed_ns[ns] = true

  return run_gen("gen_ns_note", ofile,
  {
    "--header="..header,
    "--namespace="..ns,
  }, lpp_params)
end

---@param params tools.docgen.Params
return function(params)
  local doc_dir = params.cwd.."/_doc"

  local lpp_params = {}
  setmetatable(lpp_params, { __index = params.lpp_params })

  lpp_params.gen_meta = false

  local headers = List { }

  local function getHeaders(pattern)
    for header in lake.utils.glob(pattern):each() do
      headers:push(header)
    end
  end

  getHeaders "src/**/*.lh"
  getHeaders "include/iro/**/*.h"

  local processed = {}

  for header in headers:each() do
    lpp_params.meta_args = List{}
    lpp_params.meta_args:pushList(params.lpp_params.meta_args)
    lpp_params.meta_args:push("--header="..header)

    local types_filename = doc_dir.."/_types/"..header..".types"

    local types_lpp = 
      o.Lpp "tools/docgen/get_header_types.lpp"
        :preprocess(types_filename, lpp_params)

    lake.task("generate "..header.." notes")
      :dependsOn(types_lpp.task)
      :cond(function() return true end)
      :recipe(function()
        local tfile = io.open(types_filename, "r")
        local types = tfile:read("*a")
        tfile:close()
        for type in types:gmatch("type%s*(%b{})") do
          local data = loadstring("return "..type)()

          local ofile = doc_dir.."/"..data.csafe..".md"
          run_type_gen(ofile, header, data.qname, lpp_params)
        end

        for ns in types:gmatch("namespace%s*(%b{})") do
          local data = loadstring("return "..ns)()

          local ofile = doc_dir.."/ns_"..data.csafe..".md"
          run_ns_gen(ofile, header, data.csafe, lpp_params)
        end
      end)
  end
end

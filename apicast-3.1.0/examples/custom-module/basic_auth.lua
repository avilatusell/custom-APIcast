-- load and initialize the parent module
local apicast = require('apicast').new()

-- _NAME and _VERSION are used in User-Agent when connecting to the Service Management API
local _M = { _VERSION = '0.0', _NAME = 'Example Module' }
-- define a table, that is going to be this module metatable
-- if your table does not define a property, __index is going to get used
-- and so on until there are no metatables to check
-- so in this case the inheritance works like local instance created with _M.new() -> _M -> apicast`
local mt = { __index = setmetatable(_M, { __index = apicast }) }

function _M.new()
  -- this method is going to get called after this file is required
  -- so create a new table for the internal state (global) and set the metatable for inheritance
  return setmetatable({}, mt)
end

-- to run some custom code in the log phase let's override the method

-- encoding
function encode(data)
// function to base-64 encode "data"
end

-- decoding
function decode(data)
// function to base-64 decode "data"
end



function first_values(a)
  r = {}
  for k,v in pairs(a) do
    if type(v) == "table" then
      r[k] = v[1]
    else
      r[k] = v
    end
  end
  return r
end


function extractAuthHeader()
  local params = {}
  params = ngx.req.get_headers()

  if params["Authorization"] then
    local m = ngx.re.match(params["Authorization"], "Basic\\s(.+)")
    local decoded = decode(m[1])

    params.app_id = string.split(decoded, ":")[1]
    params.app_id = params.app_id:gsub("%s+", "") --trim spaces

    params.app_key = string.split(decoded, ":")[2]
    params.app_key = params.app_key:gsub("%s+", "") --trim spaces
  end
  return first_values(params)
end

--In service specific block towards the end of the lua file, replace:
--local parameters = get_auth_params(<params>)
--with:
--local parameters = extractAuthHeader()

return _M


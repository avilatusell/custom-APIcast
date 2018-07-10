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
function _M.log()
  ngx.log(ngx.WARN,
    'upstream response time: ', ngx.var.upstream_response_time, ' ',
    'upstream connect time: ', ngx.var.upstream_connect_time, ' ',
    'request time: ', ngx.var.request_time)
  -- and the original apicast method should be executed too
  return apicast:log()
end

return _M
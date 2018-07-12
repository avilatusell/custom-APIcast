--[[ Description: Parses 3scale Authorization response to check 
     for authorization reason and return appropriate http status 
	 code and message back to the client]]


-- load and initialize the parent module
local apicast = require('apicast').new()
local xml = require 'xml'
local proxy = require 'proxy'

-- _NAME and _VERSION are used in User-Agent when connecting to the Service Management API
local _M = { _VERSION = '0.0', _NAME = 'Example Module' }
-- define a table, that is going to be this module metatable
-- if your table does not define a property, __index is going to get used
-- and so on until there are no metatables to check
-- so in this case the inheritance works like local instance created with _M.new() -> _M -> apicast`
local mt = { __index = setmetatable(_M, { __index = apicast }) }

-- adds custom errors. This is normally set in Service.new in configuration.lua
local limits_exceeded = {
	limits_exceeded_headers = 'text/plain; charset=us-ascii',
	error_limits_exceeded = 'rate limit exceeded',
	limits_exceeded_status = 429	
}


function _M.new()
  -- this method is going to get called after this file is required
  -- so create a new table for the internal state (global) and set the metatable for inheritance
  return setmetatable({}, mt)
end


function error_limits_exceeded(cached_key)
   ngx.log(ngx.INFO, 'rate limit exceed', cached_key)
   ngx.status = limits_exceeded.limits_exceeded_status
   ngx.header.content_type = limits_exceeded.limits_exceeded_headers
   ngx.print(limits_exceeded.error_limits_exceeded)
   ngx.exit(429) 
end




proxy.handle_backend_response = function (cached_key, response, ttl)
  ngx.log(ngx.DEBUG, '[backend] response status: ', response.status, ' body: ', response.body)
 
--[[
  return self.cache_handler(self.cache, cached_key, response, ttl)
   cache_handler returns 
      true  if response.status == 200
      false if response.statu  ~= 200
   ]] 

	if not self.cache_handler(self.cache, cached_key, response, ttl)  then

	  -- check rejection reason -- to be reviewd
	  local result_body = xml.load(response.body)
	  local reason = xml.find(result_body, 'reason')[1]
	  
	  if response.status == 409 and reason == 'usage limits are exceeded' then
	    error_limits_exceeded(cached_key)
	  else
	  	error_authorization_failed(service) 

       -- end of check rejection reason -- to be reviewd
       end
    end
      
   return self.cache_handler(self.cache, cached_key, response, ttl)

end








return _M
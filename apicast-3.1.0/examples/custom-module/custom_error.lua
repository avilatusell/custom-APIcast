--[[ Description: Parses 3scale Authorization response to check 
     for authorization reason and return appropriate http status 
	 code and message back to the client]]


-- load and initialize the parent module
local apicast = require('apicast').new()
local proxy = require 'proxy'
local threescale_utils = require 'threescale_utils'

-- _NAME and _VERSION are used in User-Agent when connecting to the Service Management API
local _M = { _VERSION = '3.1', _NAME = 'Custom error module' }
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


local function error_limits_exceeded(cached_key)
   ngx.log(ngx.INFO, 'rate limit exceed', cached_key)
   ngx.var.cached_key = nil -- added  
   ngx.status = limits_exceeded.limits_exceeded_status
   ngx.header.content_type = limits_exceeded.limits_exceeded_headers
   ngx.print(limits_exceeded.error_limits_exceeded)
   return ngx.exit(ngx.HTTP_OK) -- changed 
end


proxy.handle_backend_response = function (self, cached_key, response, ttl) -- adding "self" as _M:handle_backend_response in proxy.lua
  ngx.log(ngx.DEBUG, '[backend] response status: ', response.status, ' body: ', response.body)


-- if TRUE ( = not (handlers.strict = false = response != 200) )  then--
	if not self.cache_handler(self.cache, cached_key, response, ttl)  then
    ngx.log(ngx.DEBUG,"Debug: I'm using custom error module") 
	  -- check rejection reason -

	  local reason = threescale_utils.match_xml_element(response.body, 'reason', 'usage limits are exceeded' )
    ngx.log(ngx.DEBUG, "the value of the reason is: " .. require('inspect')(reason))
	  
	  if response.status == 409 and reason  then --see line 97 in oauth/apicast_oauth/authorize.lua
	    error_limits_exceeded(cached_key)
    end
    -- end of check rejection reason 
  end
      
  return self.cache_handler(self.cache, cached_key, response, ttl)

end

return _M


--[[
function _M.match_xml_element(xml, element, value)
  if not xml then return nil end
  local pattern = string.format('<%s>%s</%s>', element, value, element)
  return string.find(xml, pattern, xml_header_len, xml_header_len, true)
end
   ]] 



--[[
  return self.cache_handler(self.cache, cached_key, response, ttl)
   cache_handler returns 
      true  if response.status == 200
      false if response.statu  ~= 200
   ]] 


--[[
Response object when key is valid: 
 
     local res =  {
      body = '<?xml version="1.0" encoding="UTF-8"?><status><authorized>true</authorized><plan>Basic</plan></status>',
      header = {
        ["Access-Control-Allow-Origin"] = "*",
        ["Access-Control-Expose-Headers"] = "ETag, Link, 3scale-rejection-reason",
        ["Content-Length"] = 102,
        ["Content-Type"] = "application/vnd.3scale-v2.0+xml",
        ["X-Content-Type-Options"] = "nosniff"
      },
      status = 504,
      truncated = false
    }

    
Response object when key is invalid: 

2018/07/16 09:11:04 [debug] 21#21: *9 [lua] proxy.lua:216: access(): response object: {
  body = '<?xml version="1.0" encoding="UTF-8"?><status><authorized>false</authorized><reason>application key "a161e963f228c2b2a6ab38d9734629ffxxx" is invalid</reason><plan>Basic</plan></status>',
  header = {
    ["Access-Control-Allow-Origin"] = "*",
    ["Access-Control-Expose-Headers"] = "ETag, Link, 3scale-rejection-reason",
    ["Content-Length"] = 184,
    ["Content-Type"] = "application/vnd.3scale-v2.0+xml",
    ["X-Content-Type-Options"] = "nosniff"
  },
  status = 409,
  truncated = false
}

Response object when rate limit is exceeded:
2018/07/16 09:51:53 [debug] 22#22: *13 [lua] proxy.lua:216: access(): response object: {
  body = '<?xml version="1.0" encoding="UTF-8"?><status><authorized>false</authorized><reason>usage limits are exceeded</reason><plan>Basic</plan><usage_reports><usage_report metric="kayakers" period="minute"><period_start>2018-07-16 09:51:00 +0000</period_start><period_end>2018-07-16 09:52:00 +0000</period_end><max_value>2</max_value><current_value>2</current_value></usage_report></usage_reports></status>',
  header = {
    ["Access-Control-Allow-Origin"] = "*",
    ["Access-Control-Expose-Headers"] = "ETag, Link, 3scale-rejection-reason",
    ["Content-Length"] = 399,
    ["Content-Type"] = "application/vnd.3scale-v2.0+xml",
    ["X-Content-Type-Options"] = "nosniff"
  },
  status = 409,
  truncated = false
}

 ]] 
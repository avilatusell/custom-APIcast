local apicast = require('apicast').new()

local _M = { _VERSION = '0.0' }
local mt = { __index = setmetatable(_M, { __index = apicast }) }

function _M.new()
  return setmetatable({}, mt)
end

function _M.log()
  ngx.log(ngx.WARN,
    'upstream response time: ', ngx.var.upstream_response_time, ' ',
    'upstream connect time: ', ngx.var.upstream_connect_time)
  return apicast:log()
end

return _M


-------------------------

local apicast = require('apicast').new()

local _M = { _VERSION = '0.0' }
local mt = { __index = setmetatable(_M, { __index = apicast }) }

function _M.new()
  return setmetatable({}, mt)
end


-----------


function _M:authorize(service, usage, credentials, ttl)
  if usage == '' then
    return error_no_match(service)
  end

  output_debug_headers(service, usage, credentials)

  local internal_location = (self.oauth and '/threescale_oauth_authrep') or '/threescale_authrep'

  -- usage and credentials are expected by the internal endpoints
  ngx.var.usage = usage
  ngx.var.credentials = credentials
  -- NYI: return to lower frame
  local cached_key =  ngx.var.cached_key.. ":" .. usage
  local cache = self.cache
  local is_known = cache:get(cached_key)

  if is_known == 200 then
    ngx.log(ngx.DEBUG, 'apicast cache hit key: ', cached_key)
    ngx.var.cached_key = cached_key
  else
    --custom code 
    local res = http.get(internal_location)
    if res. status == 504 then
      log("DEBUG: TIMEOUT WHILE TRYING TO REACH 3SCALE")




    ngx.log(ngx.INFO, 'apicast cache miss key: ', cached_key, ' value: ', is_known)

    -- set cached_key to nil to avoid doing the authrep in post_action
    ngx.var.cached_key = nil

    

    if not self:handle_backend_response(cached_key, res, ttl) then
      error_authorization_failed(service)
    end
  end
end

return _M
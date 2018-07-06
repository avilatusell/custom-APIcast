-- This module customizes the cache_handler. In case the proxy is not able to reach 
-- the 3scale service management API, it will allow the traffic to go through to the
-- API, only for a selected group of applications defined in a whitelist, 

local whitelist = require "whitelist"

local apicast = require('apicast').new()
local cache_handler = require('backend.cache_handler')

local _M = {
  _VERSION = '3.0.1',
  _NAME = 'failover cache policy in case 3scale cannot be reached'
}

local mt = { __index = setmetatable(_M, { __index = apicast }) }

function _M.new()
  return setmetatable({}, mt)
end


cache_handler.handlers.strict = function (cache, cached_key, response, ttl)
  if response.status == 200 then
    ngx.log(ngx.DEBUG, "using failover_cache module")
    -- cached_key is set in post_action and it is in in authorize
    -- so to not write the cache twice lets write it just in authorize
    if ngx.var.cached_key ~= cached_key then
      ngx.log(ngx.INFO, 'apicast cache write key: ', cached_key, ', ttl: ', ttl )
      cache:set(cached_key, 200, ttl or 0)
    end
    return true

  elseif response.status == 504 then
    ngx.log(ngx.DEBUG,"Debug: timeout while trying to reach 3scale") 
    local credentials = ngx.var.credentials -- the value of ngx.var.credentials is set in line 199 from proxy.lua
    if whitelist[credentials.app_id] then
      ngx.log(ngx.INFO, 'apicast cache write key: ', cached_key, ', ttl: ', ttl )
      cache:set(cached_key, 200, ttl or 0)
    end
    return true

  else
    ngx.log(ngx.DEBUG, "using failover_cache module")
    ngx.log(ngx.NOTICE, 'apicast cache delete key: ', cached_key, ' cause status ', response.status)
    cache:delete(cached_key)
    return false, 'not authorized'
  end

end
return _M
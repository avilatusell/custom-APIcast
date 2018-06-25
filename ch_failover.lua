local whitelist = require "whitelist"

function authrep(params, service)
  ngx.var.cached_key = ngx.var.cached_key .. ":" .. ngx.var.usage
  local api_keys = ngx.shared.api_keys
  local is_known = api_keys:get(ngx.var.cached_key)

  if is_known ~= 200 then
    local res = ngx.location.capture("/threescale_authrep", { share_all_vars = true })
    
    if res.status == 504 then
    -- 3scale could not be reached. Fall back to fixed cache
      log("DEBUG: TIMEOUT WHILE TRYING TO REACH 3SCALE")
      if whitelist[params.app_id] then
        log("DEBUG: application in cache")
        ngx.status = 200
        return
     else
        log("DEBUG: application not in cache")
        error_authorization_failed(service)
      end
    end

    if res.status ~= 200 then
      -- remove the key, if it's not 200 let's go the slow route, to 3scale's backend
      api_keys:delete(ngx.var.cached_key)
      ngx.status = res.status
      ngx.header.content_type = "application/json"
      error_authorization_failed(service)
    else
      api_keys:set(ngx.var.cached_key,200)
    end
    ngx.var.cached_key = nil
  end

end
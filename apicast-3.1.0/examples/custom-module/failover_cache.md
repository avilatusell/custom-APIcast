# Failover cache module 

This custom module overrides 
`function _M.handlers.strict(cache, cached_key, response, ttl)`

from `cache_handler.lua`

It adds the following logic: 

```
  elseif response.status == 504 then
    ngx.log(ngx.DEBUG,"Debug: timeout while trying to reach 3scale") 
    local credentials = ngx.var.credentials 
    if whitelist[credentials.app_id] then
      ngx.log(ngx.INFO, 'apicast cache write key: ', cached_key, ', ttl: ', ttl )
      cache:set(cached_key, 200, ttl or 0)
    end
    return true
 ```

 and the file `whitelist.lua` with the allowed credentials when having a 504 error. 

In order to test it, the response from `proxy.lua` in the Authorize function has been modified (hardcoded) as following: 

First, added a log to see how is the response: 
`ngx.log(ngx.DEBUG, "response object: " .. require('inspect')(res))`

After a first call to see how is the response object, the response.status has been replaced by a hardcoded status code 504:

```
    --local res = http.get(internal_location)
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
```

To start docker, you need to: 
1) mount the custom proxy.lua, by mounting the custom file as a volume that will replace the original one.
2) mount the custom module and use the APICAST_MODULE env var to start APIcast with the custom module. 

```
docker run --rm --name apicast -p 8080:8080 -p 8090:8090   -e THREESCALE_PORTAL_ENDPOINT=https://<access_token>@<domain>-admin.3scale.net   -e THREESCALE_DEPLOYMENT_ENV=staging   -e APICAST_MANAGEMENT_API=debug   -e APICAST_CONFIGURATION_LOADER=lazy   -e APICAST_LOG_LEVEL=debug   -v /Users/avilatus/projects/apicast_31/apicast-3.1.0/apicast/src/proxy.lua:/opt/app-root/src/src/proxy.lua   -v $(pwd)/failover_cache.lua:/opt/app-root/src/src/failover_cache.lua   -v $(pwd)/whitelist.lua:/opt/app-root/src/src/whitelist.lua   -e APICAST_MODULE=failover_cache   registry.access.redhat.com/3scale-amp21/apicast-gateway:latest
```



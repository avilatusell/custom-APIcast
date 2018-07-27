# Custom error module
This custom module overrides `function _M:handle_backend_response(cached_key, response, ttl)` from `proxy.lua` file. It adds a function that parses 3scale Authorization response to check for authorization reason and returns appropriate http status code and message back to the client.

The first thing to understand is what Authorization response returns. A log is introduced in `proxy.lua` file to study the response: 

`ngx.log(ngx.DEBUG, "response object: " .. require('inspect')(res))`
`
and a limit is set for the methow in the admin portal. 
The response when the limit is reached is: 

```
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
```

The reason is: 
`<reason>usage limits are exceeded</reason>` and `status = 409`.

If the response is not `200, `cache_handler` returns `false` so that `error_authorization_failed` is called in `authorize` function:

    if not self:handle_backend_response(cached_key, res, ttl) then
      error_authorization_failed(service)
    end

Instead of calling `error_authorization_failed(service)` we'd like to call another function that throws an error when limits are reached. 

We define the function `error_limits_exceeded` and modify the function `handle_backend_response` to trow the error `rate limit exceeded` when the status is `409 and the message reason is `usage limits are exceeded` in `custom_error.lua`.

When we make a request and the limits are exceeded, the response is: 

    558[~]$ curl "http://localhost:8080/api/kayakers?user_key=<user_key>" -v
    *   Trying ::1...
    * TCP_NODELAY set
    * Connected to localhost (::1) port 8080 (#0)
    > GET /api/kayakers?user_key=<user_key> HTTP/1.1
    > Host: localhost:8080
    > User-Agent: curl/7.54.0
    > Accept: */*
    >
    < HTTP/1.1 429
    < Server: openresty/1.11.2.4
    < Date: Mon, 23 Jul 2018 09:44:05 GMT
    < Content-Type: text/plain; charset=us-ascii
    < Transfer-Encoding: chunked
    < Connection: keep-alive
    <
    * Connection #0 to host localhost left intact
    rate limit exceeded


The Docker command to start the gateway is: 

```
docker run --rm --name apicast -p 8080:8080 -p 8090:8090 \
 -e THREESCALE_PORTAL_ENDPOINT=https://<secret_token>@<account>-admin.3scale.net \
 -e THREESCALE_DEPLOYMENT_ENV=staging \
 -e APICAST_MANAGEMENT_API=debug \
 -e APICAST_CONFIGURATION_LOADER=lazy \
 -e APICAST_LOG_LEVEL=debug \
 -v /Users/avilatus/projects/apicast_31/apicast-3.1.0/apicast/src/proxy.lua:/opt/app-root/src/src/proxy.lua \
 -v $(pwd)/custom_error.lua:/opt/app-root/src/src/custom_error.lua \
 -e APICAST_MODULE=custom_error \
 registry.access.redhat.com/3scale-amp21/apicast-gateway:latest
 ```
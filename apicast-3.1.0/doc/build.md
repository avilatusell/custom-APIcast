# Build process and components

APIcast is [OpenResty](https://openresty.org/en/) application. It consits of two parts: nginx configuration and lua files.

## Release

APIcast is released as [Docker image](https://docs.docker.com/engine/tutorials/dockerimages/). 

## Dependencies

APIcast uses LuaRocks to install dependencies. LuaRocks have to be properly configured,
so it installs dependencies into correct path where OpenResty can see them. In the Docker image, rocks are installed into the application folder.
Then this folder is added to the load path by `luarocks path`. 

Lua Dependencies are defined in [`apicast-VERSION.rockspec`](https://github.com/3scale/apicast/blob/50daf279b3cf2da80b20ad473ec820d7a364b688/apicast-0.1-0.rockspec) file.

* `lua-resty-http` cosocket based http client to be used instead of the `ngx.location.capture`
* `inspect` library to pretty print data structures
* `router` used to implement internal APIs

## Components

APIcast is using [source-to-image](https://github.com/openshift/source-to-image) to build the final Docker image.
You'll need to have source-to-image installed and available on your system.

The builder image used is [s2i-openresty](https://github.com/3scale/s2i-openresty).
It is not very light builder image as it builds on heavy openshift base images.
In the future we would like to utilize s2i extended build and use very minimal runtime image.

## Build process

The build is defined in `Makefile`. The [`make build`](https://github.com/3scale/apicast/blob/bc8631fcf91fcab25cae84152e16536ce01d22be/Makefile#L31-L32) is meant for development and uses s2i incremental build.
The [`make release`](https://github.com/3scale/apicast/blob/bc8631fcf91fcab25cae84152e16536ce01d22be/Makefile#L34-L35) is for release build. 

Both use the [s2i-openresty](https://github.com/3scale/s2i-openresty) builder image pushed to [`quay.io/3scale/s2i-openresty-centos`](https://quay.io/repository/3scale/s2i-openresty-centos7?tag=latest).

## Release

`master` branch is automatically built and pushed on every successful build [by Travis](https://github.com/3scale/apicast/blob/bc8631fcf91fcab25cae84152e16536ce01d22be/.travis.yml#L51-L56) to [`quay.io/3scale/apicast:master`](https://quay.io/repository/3scale/apicast?tab=tags&tag=master).






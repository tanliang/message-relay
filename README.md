# message
基于 openresty (nginx + lua + redis) 的消息服务（私信）

Nginx 配置：
```nginx
location ~ ^/app/([-_a-zA-Z0-9/]+) {
        content_by_lua_file conf/app_$1.lua;
}
```

参考：https://github.com/openresty/lua-resty-redis

其他请看 README.pdf

# message
基于 openresty (nginx + lua + redis) 的消息服务（私信），http://xxx.com/api/message?type=message&do=get&token=xxx

Nginx 配置：
```nginx
location ~ ^/api/([-_a-zA-Z0-9/]+) {
        content_by_lua_file conf/api_$1.lua;
}
```

Redis 参考：https://github.com/openresty/lua-resty-redis

其他请参看 README.pdf

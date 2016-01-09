# message
message relay center build on openresty

# nginx configure

```nginx
location ~ ^/app/([-_a-zA-Z0-9/]+) {
        content_by_lua_file conf/app_$1.lua;
}
```

# message send

curl -d "$json" http://xxx.com/app/message?type=message&do=set&token=xxx&md5_id=xxx

```json
{ 
"time":1449024499,
"nickname":"github",
"content":"what's up man!", 
"icon":"http://xxx.jpg", 
"redirect":"http://xxx",
"type":"0"
}
```

# message recv

curl http://xxx.com/app/message?type=message&do=get&token=xxx

```json
{ 
"md5_id":"5f8831aa46c5a6989ffbff1132430812",
"time":1449024499,
"nickname":"github",
"content":"what's up man!", 
"icon":"http://xxx.jpg", 
"redirect":"http://xxx",
"type":"0"
}
```

# blacklist add

curl -d "$json" http://xxx.com/app/message?type=blacklist&do=set&token=xxx&md5_id=xxx

```json
{ 
"nickname":"github",
"icon":"http://xxx.jpg", 
}
```

# blacklist get

curl http://xxx.com/app/message?type=blacklist&do=get&token=xxx

```json
[{
"md5_id":"5f8831aa46c5a6989ffbff1132430812", 
"nickname":"github",
"icon":"http://xxx.jpg", 
}]
```

# blacklist del

curl http://xxx.com/app/message?type=blacklist&do=del&token=xxx&md5_id=xxx

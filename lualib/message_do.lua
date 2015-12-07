message_do = {}

-- admin account has no limit for set or get message
message_do.admin = {
    ["5f8831aa46c5a6989ffbff1132430812"] = "test"
}

message_do.total_limit = 300
message_do.expire = 3 * 24 * 3600

message_do.output = require("output")
message_do.cache = require("my_redis")
message_do.args = nil
message_do.my_id = nil
message_do.key = nil

message_do.prepare = function (auth) 
    local tool = require("tool")
    
    -- verify args
    local res, err = tool.auth_args(auth, ngx.req.get_uri_args())
    if not res then
        message_do.output.args_invalid(err)
    end
    message_do.args = res
    
    -- get my_id by decode token or just use token
    message_do.my_id = ngx.md5(message_do.args["token"])
    message_do.key = message_do.args["type"].."|"..message_do.my_id
    
    message_do.cache.connect("pass")
end

message_do.get = {
    ["blacklist"] = function ()
        local tool = require("tool")
        return tool.nil2val(message_do.cache.hgetall(message_do.key))
    end,
    ["message"] = function ()
        local time = os.time()
        local res = message_do.cache.exec("zrevrangebyscore", message_do.key, time, message_do.args["time"])
        message_do.cache.exec("zremrangebyscore", message_do.key, 0, time - message_do.expire)
        local tool = require("tool")
        return tool.nil2val(res)
    end
}

message_do.set = {
    ["blacklist"] = function (json)
        if json["nickname"] == nil or string.len(json["nickname"]) == 0 then
            message_do.output.args_invalid("nickname is empty")
        end
        
        if message_do.admin[message_do.args["md5_id"]] ~= nil then
            message_do.output.args_invalid("md5_id invalid")
        end

        --if json["reason"] == nil or string.len(json["reason"]) == 0 then
        --    output.args_invalid("reason is empty")
        --end

        json["md5_id"] = message_do.args["md5_id"]
        
        local cjson = require("cjson")
        message_do.cache.exec("hset", message_do.key, message_do.args["md5_id"], cjson.encode(json))
        message_do.cache.exec("hincrby", "total|blacklist", message_do.args["md5_id"], 1)
    end,
    ["message"] = function (json)
        -- is in blacklist

        local res = message_do.cache.exec("hget", "total|blacklist", message_do.my_id)
        if res ~= ngx.null and tonumber(res) > message_do.total_limit then
            message_do.output._error("501", "in blacklist")
        end
        
        local res = message_do.cache.exec("hexists", "blacklist|"..message_do.args["md5_id"], message_do.my_id)
        if res == 1 then
            message_do.output._error("501", "in blacklist")
        end
        
        local key = message_do.args["type"].."|"..message_do.args["md5_id"]

        -- is total over limited
        local res = message_do.cache.exec("zcount", key, 0, os.time())
        if message_do.admin[message_do.my_id] == nil and message_do.admin[message_do.args["md5_id"]] == nil and res >= message_do.total_limit then
            message_do.output._error("502", "total limited")
        end
    
        -- res contains a valid json object
        if json["content"] == nil or string.len(json["content"]) == 0 then
            message_do.output.args_invalid("content is empty")
        elseif string.len(json["content"]) > message_do.total_limit then
            message_do.output.args_invalid("content too long")
        end
        
        json["md5_id"] = message_do.my_id
        json["time"] = os.time()
                
        local cjson = require("cjson")
        message_do.cache.exec("zadd", key, os.time(), cjson.encode(json))
    end
}

message_do.del = {
    ["blacklist"] = function ()
        if message_do.args["md5_id"] ~= nil and string.len(message_do.args["md5_id"]) > 0 then
            message_do.cache.exec("hdel", message_do.key, message_do.args["md5_id"])
            message_do.cache.hdel("total|blacklist", message_do.args["md5_id"])
        else
            local res = message_do.cache.hgetall(message_do.key, true)
            table.foreach(res, function (i, v)
                message_do.cache.hdel("total|blacklist", i)
            end)
            message_do.cache.exec("del", message_do.key)
        end
    end,
    ["message"] = function ()
        message_do.cache.exec("del", message_do.key)
    end
}

return message_do
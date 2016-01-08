local output = require('output')
local cjson = require("cjson")
local rdb = require('rdb')

local _M = {
    _VERSION = '0.10'
}

local mt = { __index = _M }

local whitelist = {
    ["ba58ea74xhdywf504869944a840aaf7b"] = "whitelist"
}

local total_limit = 300
local limit_base  = 100
local limit_times = 3

local function auth(auth_dict, args) 
    local res = {}
    local err = nil
    table.foreach(auth_dict, function(i, v) 
        res[i] = args[i]
        if args[i] == nil or string.len(args[i]) == 0 then
            if v == "required" then
                err = i
            end
            res[i] = v
        end 
    end)
    if err then
        res = nil
    end
    return res, err
end

local function check(t)
    if t == nil or _G.next(t) == nil then
        return nil
    else
        table.foreach(t, function(i, v) t[i] = cjson.decode(v) end)
        return t
    end
end

local function _json(str)
    local ok, res = pcall(cjson.decode, str)
    if not ok then
        -- res contains the error message
        output.args_invalid("post no json")
    end
    return res
end

local function split(s, p)
    local res = {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(res, w) end )
    return res
end

function _M.init(auth_dict) 
    -- verify args
    local res, err = auth(auth_dict, ngx.req.get_uri_args())
    if not res then
        output.args_invalid(err)
    end
    ngx.ctx.args = res

    ngx.ctx.token_id = ngx.md5(res["token"])
    ngx.ctx.token_key = res["type"].."|"..ngx.ctx.token_id
    rdb.connect()
end

_M.get = {
    ["blacklist"] = function ()
        return check(rdb.hgetall(ngx.ctx.token_key))
    end,
    ["message"] = function ()
        local time = os.time()
        local res = check(rdb.exec("zrevrangebyscore", ngx.ctx.token_key, time, 0))
        if res then
            rdb.exec("zremrangebyscore", ngx.ctx.token_key, 0, time)
        end
        return res
    end
}

_M.set = {
    ["blacklist"] = function (post)
        json = _json(post)
        if json["nickname"] == nil or string.len(json["nickname"]) == 0 then
            output.args_invalid("nickname is empty")
        end

        if whitelist[ngx.ctx.args["md5_id"]] ~= nil then
            output.args_invalid("md5_id invalid")
        end

        --if json["reason"] == nil or string.len(json["reason"]) == 0 then
        --    output.args_invalid("reason is empty")
        --end

        json["md5_id"] = ngx.ctx.args["md5_id"]
        
        rdb.exec("hset", ngx.ctx.token_key, ngx.ctx.args["md5_id"], cjson.encode(json))
        rdb.exec("hincrby", "total|blacklist", ngx.ctx.args["md5_id"], 1)
    end,
    ["message"] = function (post)
        json = _json(post)
        -- is in blacklist
        local res = rdb.exec("hget", "total|blacklist", ngx.ctx.token_id)
        if res ~= ngx.null and tonumber(res) > total_limit then
            output._error("501", "in blacklist")
        end
        
        local res = rdb.exec("hexists", "blacklist|"..ngx.ctx.args["md5_id"], ngx.ctx.token_id)
        if res == 1 then
            output._error("501", "in blacklist")
        end
        
        local key = ngx.ctx.args["type"].."|"..ngx.ctx.args["md5_id"]

        -- is total over limited
        local res = rdb.exec("zcount", key, 0, os.time())
        if whitelist[ngx.ctx.token_id] == nil and whitelist[ngx.ctx.args["md5_id"]] == nil and res >= total_limit then
            output._error("502", "total limited")
        end
        
        -- is send message too fast, if 5 minutes send over 100 message
        if whitelist[ngx.ctx.token_id] == nil then
            local key_for_send_message_to_fast = ngx.ctx.token_id.."|"..tostring(total_limit)
            local res = rdb.exec("incr", key_for_send_message_to_fast)
            if res == 1 then
                rdb.exec("expire", key_for_send_message_to_fast, total_limit)
            end
            
            if res > limit_base then
                output._error("503", "send message to fast")
            end
        end        
    
        -- res contains a valid json object
        if json["content"] == nil or string.len(json["content"]) == 0 then
            output.args_invalid("content is empty")
        elseif string.len(json["content"]) > total_limit then
            output.args_invalid("content too long")
        end
        
        json["md5_id"] = ngx.ctx.token_id
        
        if json["time"] == nil then
            json["time"] = os.time()
        end
                
        rdb.exec("zadd", key, json['time'], cjson.encode(json))
    end
}

_M.del = {
    ["blacklist"] = function ()
        if ngx.ctx.args["md5_id"] ~= nil and string.len(ngx.ctx.args["md5_id"]) > 0 then
            rdb.exec("hdel", ngx.ctx.token_key, ngx.ctx.args["md5_id"])
            rdb.hdel("total|blacklist", ngx.ctx.args["md5_id"])
        else
            local res = rdb.hgetall(ngx.ctx.token_key, true)
            table.foreach(res, function (i, v)
                rdb.hdel("total|blacklist", i)
            end)
            rdb.exec("del", ngx.ctx.token_key)
        end
    end,
    ["message"] = function ()
        rdb.exec("del", ngx.ctx.token_key)
    end
}

return _M
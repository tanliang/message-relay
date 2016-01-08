local redis = require "resty.redis"   
local output = require("output")

local _M = {
    _VERSION = '0.10'
}

local mt = { __index = _M }

local commands = {
    ["expire"] = function (arg)
        return ngx.ctx.rdb:expire(arg[1], arg[2])
    end,
    ["incr"] = function (arg)
        return ngx.ctx.rdb:incr(arg[1])
    end,
    ["zrevrangebyscore"] = function (arg)
        return ngx.ctx.rdb:zrevrangebyscore(arg[1], arg[2], arg[3])
    end,
    ["zremrangebyscore"] = function (arg)
        return ngx.ctx.rdb:zremrangebyscore(arg[1], arg[2], arg[3])
    end,
    ["zadd"] = function (arg)
        return ngx.ctx.rdb:zadd(arg[1], arg[2], arg[3])
    end,
    ["del"] = function (arg)
        return ngx.ctx.rdb:del(arg[1])
    end,
    ["zcount"] = function (arg)
        return ngx.ctx.rdb:zcount(arg[1], arg[2], arg[3])
    end,
    ["hset"] = function (arg)
        return ngx.ctx.rdb:hset(arg[1], arg[2], arg[3])
    end,
    ["hgetall"] = function (arg)
        return ngx.ctx.rdb:hgetall(arg[1])
    end,
    ["hdel"] = function (arg)
        return ngx.ctx.rdb:hdel(arg[1], arg[2])
    end,
    ["hexists"] = function (arg)
        return ngx.ctx.rdb:hexists(arg[1], arg[2])
    end,
    ["hget"] = function (arg)
        return ngx.ctx.rdb:hget(arg[1], arg[2])
    end,
    ["hincrby"] = function (arg)
        return ngx.ctx.rdb:hincrby(arg[1], arg[2], arg[3])
    end
}

function _M.connect(sock, pass)
    ngx.ctx.rdb = redis:new()
    ngx.ctx.rdb:set_timeout(1000)
    
    local _sock = sock or 'unix:/tmp/redis.sock'
    local ok, err = ngx.ctx.rdb:connect(_sock)
    if not ok then
        output.server_err('redis', 'connect failed')
    end
    
    local _pass = pass or 'fK3qvYq3SSyiah6u'
    local ok, err = ngx.ctx.rdb:auth(_pass)
    if not ok then
        output.server_err('redis', 'auth failed')
    end
end

function _M.hgetall(key, assoc)
    local all = _M.exec("hgetall", key)
    
    local res = {}
    if all ~= false then
        local _next
        for i, v in ipairs(all) do
            if i % 2 == 1 then
                _next = v
            else
                if assoc == nil then
                    table.insert(res, v)
                else
                    res[_next] = v 
                end
            end
        end
    end

    return res
end

function _M.hdel(key, hash)
    local res = _M.exec("hincrby", key, hash, -1)
    
    if res ~= nil and res < 1 then
         _M.exec("hdel", key, hash)
    end
end

function _M.exec(act, ...)
    local res, err = commands[act]({...})
    output.verify_res("redis "..act, res, err)
    return res
end

return _M

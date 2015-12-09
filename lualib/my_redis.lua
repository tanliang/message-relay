my_redis = {}

my_redis.cache = nil

my_redis.commands = {
    ["zrevrangebyscore"] = function (arg)
        return my_redis.cache:zrevrangebyscore(arg[1], arg[2], "("..tostring(arg[3]))
    end,
    ["zremrangebyscore"] = function (arg)
        return my_redis.cache:zremrangebyscore(arg[1], arg[2], arg[3])
    end,
    ["zadd"] = function (arg)
        return my_redis.cache:zadd(arg[1], arg[2], arg[3])
    end,
    ["del"] = function (arg)
        return my_redis.cache:del(arg[1])
    end,
    ["zcount"] = function (arg)
        return my_redis.cache:zcount(arg[1], arg[2], arg[3])
    end,
    ["hset"] = function (arg)
        return my_redis.cache:hset(arg[1], arg[2], arg[3])
    end,
    ["hgetall"] = function (arg)
        return my_redis.cache:hgetall(arg[1])
    end,
    ["hdel"] = function (arg)
        return my_redis.cache:hdel(arg[1], arg[2])
    end,
    ["hexists"] = function (arg)
        return my_redis.cache:hexists(arg[1], arg[2])
    end,
    ["hget"] = function (arg)
        return my_redis.cache:hget(arg[1], arg[2])
    end,
    ["hincrby"] = function (arg)
        return my_redis.cache:hincrby(arg[1], arg[2], arg[3])
    end,
    ["auth"] = function (arg)
        return my_redis.cache:auth(arg[1])
    end,
    ["connect"] = function (arg)
        return my_redis.cache:connect(arg[1])
    end
}

my_redis.connect = function (pass, sock)
    local redis = require "resty.redis"    
    my_redis.cache = redis:new()
    my_redis.cache:set_timeout(1000) -- 1 sec
    
    sock = sock or "unix:/tmp/redis.sock"
    my_redis.exec("connect", sock)
    
    if pass then
        my_redis.exec("auth", pass)
    end
end

my_redis.hgetall = function (key, assoc)
    local all = my_redis.exec("hgetall", key)
    
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

my_redis.hdel = function (key, hash)
    local res = my_redis.cache.exec("hincrby", key, hash, -1)
    
    if res ~= nil and res < 1 then
        my_redis.cache.exec("hdel", key, hash)
    end
end

my_redis.exec = function (act, ...)
    local output = require("output")
    
    local command = my_redis.commands[act]
    if not command then
        output.server_err("my_redis", "unspport command: "..act)
    end
    
    local res, err = command({...})
    output.verify_res("my_redis "..act, res, err)
    
    return res
end

return my_redis

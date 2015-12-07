local message_do = require("message_do")
message_do.prepare({["type"] = "required", ["do"] = "required", ["token"] = "required", ["time"] = "0", ["md5_id"] = ""})

-- biz handle begin
local switch = {
    ["get"] = function ()
        local f = message_do.get[message_do.args["type"]]
        if f then
            local res = f()
            if res then
                local cjson = require("cjson")
                table.foreach(res, function(i, v) res[i] = cjson.decode(v) end)
                return res
            end
        end

        return nil
    end,
    ["set"] = function ()
        if string.len(message_do.args["md5_id"]) ~= 32 then
            message_do.output.args_invalid("md5_id")
        end

        local post = ngx.var.request_body
        if post == nil or string.len(post) == 0 then
            message_do.output.args_invalid("post empty")
        end
        
        local cjson = require("cjson")
        local ok, res = pcall(cjson.decode, post)
        if not ok then
            -- res contains the error message
            message_do.output.args_invalid("post no json")
        end

        local f = message_do.set[message_do.args["type"]]
        if f then
            f(res)
        end
        
        return nil
    end,
    ["del"] = function ()
        local f = message_do.del[message_do.args["type"]]
        if f then
            f()
        end
        
        return nil
    end
}

-- output result
local f = switch[message_do.args["do"]]
if not f then
    message_do.output.args_invalid("do")
end

message_do.output.result(f())
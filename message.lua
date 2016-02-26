local output = require('output')
local msg_do = require('msg_do')

msg_do.init({["type"] = "required", ["do"] = "required", ["token"] = "required", ["md5_id"] = "", ["key"] = ""})

-- biz handle begin
local switch = {
    ["get"] = function ()
        local f = msg_do.get[ngx.ctx.args["type"]]
        if f then
            return f()
        end
        return nil
    end,
    ["set"] = function ()
        if string.len(ngx.ctx.args["md5_id"]) ~= 32 then
            output.args_invalid("md5_id")
        end

        local post = ngx.var.request_body
        if post == nil or string.len(post) == 0 then
            output.args_invalid("post empty")
        end
        
        local f = msg_do.set[ngx.ctx.args["type"]]
        if f then
            f(post)
        end
        
        return nil
    end,
    ["del"] = function ()
        local f = msg_do.del[ngx.ctx.args["type"]]
        if f then
            f()
        end
        
        return nil
    end
}

-- output result
local f = switch[ngx.ctx.args["do"]]
if not f then
    output.args_invalid("do")
end

output.result(f())
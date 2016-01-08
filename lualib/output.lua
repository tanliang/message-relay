local cjson = require("cjson")
output = {}

output.debug = function (msg)
    output._error("000", msg)
end

output.verify_res = function (_type, res, err)
    if not res then
        output.server_err(_type, err)
    end
end

output.server_err = function (_type, msg)
    output._error("500", _type.." problem: "..msg)
end

output.args_invalid = function (msg)
    output._error("003", "args invalid: "..msg)
end

output._error = function (code, msg)
    res = {
        ["success"] = 0,
        ["error"] = {
            ["code"] = code,
            ["msg"] = msg
        }
    }
    output._exit(res)
end

output.result = function (data)
    res = {["success"] = 1}
    if data ~= nil then
        res["data"] = data
    end
    output._exit(res)
end

output._exit = function (res)
    ngx.header.content_type = "application/json; charset=UTF-8";
    ngx.print(cjson.encode(res))
    ngx.exit(ngx.HTTP_OK)
end

return output
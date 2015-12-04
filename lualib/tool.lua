tool = {}

tool.split = function(s, p)
    local res = {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(res, w) end )
    return res
end

tool.nil2val = function(t)
    if t == nil or _G.next(t) == nil then
        return nil
    else
        return t
    end
end

tool.auth_args = function (auth, args) 
    local res = {}
    table.foreach(auth, function(i, v) 
        res[i] = args[i]
        if args[i] == nil then
            if v == "required" then
                return nil, i
            end
            res[i] = v
        end 
    end)
    return res, nil
end

return tool

local ClassicWoT = _G.ClassicWoT

-- list helpers
ClassicWoT.list = {}

ClassicWoT.list.reduce = function(list, fn, acc)
    for _, v in ipairs(list) do
        if acc == nil then
            acc = v
        else
            acc = fn(v, acc)
        end
    end
    return acc
end

ClassicWoT.list.sum = function(list)
    return ClassicWoT.list.reduce(list, function(a, b)
        return a + b
    end)
end

ClassicWoT.list.cnt = function(list)
    return ClassicWoT.list.reduce(list, function(_, cnt)
        return cnt + 1
    end, 0)
end

ClassicWoT.list.avg = function(list)
    return ClassicWoT.list.sum(list) / ClassicWoT.list.cnt(list)
end

ClassicWoT.list.min = function(list)
    return ClassicWoT.list.reduce(list, function(a, b)
        if a > b then
            return b
        else
            return a
        end
    end)
end

ClassicWoT.list.max = function(list)
    return ClassicWoT.list.reduce(list, function(a, b)
        if a > b then
            return a
        else
            return b
        end
    end)
end

ClassicWoT.list.cntsumminmax = function(list, valuefn)
    local cnt = 0
    local minn = nil
    local maxx = nil
    local sum = nil

    for _, v in pairs(list) do
        if valuefn ~= nil then
            v = valuefn(v)
        end

        cnt = cnt + 1

        if sum == nil then
            sum = v
        else
            sum = sum + v
        end

        if maxx == nil or v > maxx then
            maxx = v
        end
        if minn == nil or v < minn then
            minn = v
        end
    end

    return cnt, sum, minn, maxx
end

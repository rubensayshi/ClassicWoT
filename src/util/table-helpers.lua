local ClassicWoT = _G.ClassicWoT

-- table helpers
ClassicWoT.table = {}

ClassicWoT.table.contains = function(list, value)
    for _, v in pairs(list) do
        if v == value then
            return true
        end
    end

    return false
end

ClassicWoT.table.filter = function(list, filterfn)
    local result = {}
    for k, v in ipairs(list) do
        if filterfn(v) then
            result[k] = v
        end
    end

    return result
end

ClassicWoT.table.reduce = function(table, fn, acc)
    for _, v in pairs(table) do
        if acc == nil then
            acc = v
        else
            acc = fn(v, acc)
        end
    end
    return acc
end

ClassicWoT.table.sum = function(table)
    return ClassicWoT.table.reduce(table, function(a, b)
        return a + b
    end)
end

ClassicWoT.table.cnt = function(table)
    return ClassicWoT.table.reduce(table, function(_, cnt)
        return cnt + 1
    end, 0)
end

ClassicWoT.table.avg = function(table)
    return ClassicWoT.table.sum(table) / ClassicWoT.table.cnt(table)
end

ClassicWoT.table.min = function(table)
    return ClassicWoT.table.reduce(table, function(a, b)
        if a > b then
            return b
        else
            return a
        end
    end)
end

ClassicWoT.table.max = function(table)
    return ClassicWoT.table.reduce(table, function(a, b)
        if a > b then
            return a
        else
            return b
        end
    end)
end

ClassicWoT.table.cntsumminmax = function(table, valuefn)
    local cnt = 0
    local minn = nil
    local maxx = nil
    local sum = nil

    for _, v in pairs(table) do
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

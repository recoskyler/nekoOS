-- nfs - nekoFS - neko File System API
-- by recoskyler
-- 2020

local apiListFile = "/sys/api/api-list.json"

function writeFile(p, c, protect)
    local path = p or ""
    local content = c or ""

    if path == "" then return false end

    path = removeTailSlash(path)
    path = decreaseDots(path)

    if fs.exists(path) and protect then
        newPath = fs.getName(path) .. ".(" .. os.day() .. "-" .. os.time() .. ")"
        local ft = ""
        local c = 1

        while fs.exists(newPath .. ft) do
            ft = "(" .. c .. ")"
            c = c + 1
        end

        newPath = newPath .. ft

        if fs.isReadOnly(path) then return false end

        fs.copy(path, newPath)
    end

    local file = fs.open(path, "w")

    file.write(content)
    file.close()
end

function appendFile(p, c, protect)
    local path = p or ""
    local content = c or ""

    if path == "" then return false end

    path = removeTailSlash(path)
    path = decreaseDots(path)

    if fs.exists(path) and protect then
        newPath = fs.getName(path) .. ".(" .. os.day() .. "-" .. os.time() .. ")"
        local ft = ""
        local c = 1

        while fs.exists(newPath .. ft) do
            ft = "(" .. c .. ")"
            c = c + 1
        end

        newPath = newPath .. ft

        if fs.isReadOnly(path) then return false end

        fs.copy(path, (newPath))
    end

    local file = fs.open(path, "a")

    file.writeLine(content)
    file.close()
end

function readAll(p)
    local path = p or ""

    path = removeTailSlash(path)

    if not fs.exists(path) then return "" end

    local file = fs.open(path, "r")
    local content = file.readAll()

    file.close()

    return content    
end

function getUsedSpace(p)
    local path = p or "/"

    if path == "" then return 0 end

    return fs.getSize(path) - fs.getFreeSpace(path)
end

function getUsedSpacePercentage(p)
    local path = p or "/"

    if path == "" then return 0 end

    return (100 * fs.getFreeSpace(path)) / fs.getSize(path)
end

function listPaths(p, recursive, files, folders, full, res)
    local path = p or ""
    recursive = recursive or false
    res = res or {}

    path = removeTailSlash(path)

    if path == "" or not fs.exists(p) or not fs.isDir(p) then return "" end

    local fileList = fs.list(p)
    local rc = #res

    for i = 1, #fileList do
        if fs.isDir(p .. "/" .. fileList[i]) and recursive then
            if folders then
                if full then
                    res[rc] = p .. "/" .. fileList[i]                
                else
                    res[rc] = fileList[i]
                end

                rc = rc + 1
            end

            res = listPaths(p .. "/" .. fileList[i], true, files, folders, full, res)
        elseif not  fs.isDir(p .. "/" .. fileList[i]) and files then
            if full then
                res[rc] = p .. "/" .. fileList[i]                
            else
                res[rc] = fileList[i]
            end

            rc = rc + 1
        end
    end

    return res
end

function decreaseDots(path)
    while path.sub(1, 1) == "." do
        path = path.sub(2)
    end

    return "." .. path
end

function removeTailSlash(p)
    p = p or ""

    if p == "" then return "" end

    while string.sub(p, #p) == "/" do
        p = string.sub(p, 1, #p - 1)
    end

    return p
end

function hide(path)
    if fs.exists(path) and fs.getName(path).sub(1, 1) ~= "." then
        fs.move(path, "." .. path)
    end
end

function show(path)
    if fs.exists(path) and fs.getName(path).sub(1, 1) == "." then
        fs.move(path, path.sub(2))
    end
end

function listAPI()
    return textutils.unserialize(nfs.readAll(apiListFile))
end

function loadAPI()
    apiList = listAPI()
    for i, api in ipairs(apiList) do os.loadAPI(api) end
end

function addAPI(api)
    local apiList = listAPI() or {}
    local found = false

    api = decreaseDots(removeTailSlash(api))

    for i, a in ipairs(listAPI()) do 
        if removeTailSlash(a) == api then found = true end
    end

    if not found then
        apiList[#apiList + 1] = api
        writeFile(apiListFile, textutils.serialize(apiList), false)
    end
end

function removeAPI(api)
    local apiList = listAPI() or {}
    local newList = {}

    api = decreaseDots(removeTailSlash(api))

    for i, a in ipairs(listAPI()) do 
        if removeTailSlash(a) ~= api then newList[#newList + 1] = removeTailSlash(a) end
    end

    writeFile(apiListFile, textutils.serialize(newList), false)
end
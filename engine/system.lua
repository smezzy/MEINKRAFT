function require_files(files)
    for _, file in ipairs(files) do
        local file = file:sub(1, -5)
        require(file)
    end
end

function recursive_enumerate(folder, file_list)
    local file_list = file_list or {}
    local items = love.filesystem.getDirectoryItems(folder)
    for _, item in ipairs(items) do
        local file = folder .. '/' .. item
        if love.filesystem.getInfo(file).type == 'file' then
            table.insert(file_list, file)
        elseif love.filesystem.getInfo(file).type == 'directory' then
            recursive_enumerate(file, file_list)
        end
    end
    return file_list
end
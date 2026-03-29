#!/usr/bin/env lua


-- Colors
local COLORS = {
    BLUE = "\27[34m",
    GREEN = "\27[32m",
    CYAN = "\27[36m",
    RED = "\27[31m",
    YELLOW = "\27[33m",
    RESET = "\27[0m",
    BOLD = "\27[1m"
}

-- Configuration
local GITHUB_REPO = "sudoscrawl/extify-templates" -- Assuming this repo will hold templates
local RAW_BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_REPO .. "/main/"

local function color_print(color, text)
    print(color .. text .. COLORS.RESET)
end

local function show_spinner(duration, message)
    local spinner = {"|", "/", "-", "\\"}
    local delay = 0.1
    local iterations = math.floor(duration / delay)
    
    for i = 1, iterations do
        local idx = (i % #spinner) + 1
        io.write("\r" .. COLORS.CYAN .. spinner[idx] .. COLORS.RESET .. " " .. message)
        io.flush()
        -- Use a more responsive sleep if possible, or just os.execute
        os.execute("sleep " .. delay)
    end
    -- Clear the line after completion
    io.write("\r" .. (" "):rep(#message + 20) .. "\r")
    io.flush()
end

local function http_get(url)
    local tmp_file = os.tmpname()
    -- Add a timeout to curl to prevent hangs
    local curl_cmd = string.format("curl -sSL --connect-timeout 10 --max-time 30 %s -o %s", url, tmp_file)
    local success = os.execute(curl_cmd)
    
    if success ~= 0 then
        if os.remove(tmp_file) then end
        return nil
    end
    
    local f = io.open(tmp_file, "r")
    if not f then 
        return nil 
    end
    local content = f:read("*a")
    f:close()
    os.remove(tmp_file)
    
    -- Check if we got an actual file and not a 404 message from raw.github
    if content:match("^404: Not Found") then
        return nil
    end
    
    return content
end

local function write_file(path, content)
    local dir = path:match("(.+)/[^/]+$")
    if dir then
        os.execute("mkdir -p " .. dir)
    end
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

local function replace_placeholders(content, data)
    for k, v in pairs(data) do
        content = content:gsub("{{ " .. k .. " }}", v)
        content = content:gsub("{{" .. k .. "}}", v)
    end
    return content
end

-- Simplified JSON parser for the templates.json
-- Since we want to avoid libraries, we use a simple pattern matcher
local function parse_templates_json(json_str)
    local templates = {}
    -- Expecting format: [{"name": "basic", "files": ["manifest.json", ...]}, ...]
    for template_block in json_str:gmatch("{(.-)}") do
        local name = template_block:match('"name"%s*:%s*"(.-)"')
        local files_str = template_block:match('"files"%s*:%s*%[(.-)%]')
        if name and files_str then
            local files = {}
            for file in files_str:gmatch('"(.-)"') do
                table.insert(files, file)
            end
            table.insert(templates, {name = name, files = files})
        end
    end
    return templates
end

local function init_project()
    print(COLORS.BOLD .. COLORS.BLUE .. "extify" .. COLORS.RESET .. " - Browser Extension Generator\n")
    
    io.write(COLORS.CYAN .. "? " .. COLORS.RESET .. "Extension Name: ")
    local name = io.read() or "My Extension"
    if name == "" then name = "My Extension" end
    
    io.write(COLORS.CYAN .. "? " .. COLORS.RESET .. "Description: ")
    local desc = io.read() or "A browser extension"
    if desc == "" then desc = "A browser extension" end
    
    io.write(COLORS.CYAN .. "? " .. COLORS.RESET .. "Version (1.0.0): ")
    local version = io.read()
    if version == "" then version = "1.0.0" end
    
    io.write(COLORS.CYAN .. "? " .. COLORS.RESET .. "Author: ")
    local author = io.read() or ""

    print("")
    show_spinner(1.2, "Fetching templates...")
    local templates_json_url = RAW_BASE_URL .. "templates.json"
    local json_content = http_get(templates_json_url)
    
    if not json_content then
        color_print(COLORS.RED, "✖ Error: Could not connect to GitHub repository.")
        return
    end

    local templates = parse_templates_json(json_content)
    if #templates == 0 then
        color_print(COLORS.RED, "✖ Error: No templates found.")
        return
    end

    print(COLORS.BOLD .. "Select a template:" .. COLORS.RESET)
    for i, t in ipairs(templates) do
        print(string.format(COLORS.CYAN .. "  %d) " .. COLORS.RESET .. "%s", i, t.name))
    end
    
    io.write("\n" .. COLORS.CYAN .. "> " .. COLORS.RESET .. "Choice [1]: ")
    local choice_input = io.read()
    local choice = tonumber(choice_input) or 1
    local selected = templates[choice] or templates[1]

    print("\n" .. COLORS.YELLOW .. "Scaffolding " .. COLORS.BOLD .. selected.name .. COLORS.RESET .. "...")

    local data = {
        NAME = name,
        DESCRIPTION = desc,
        VERSION = version,
        AUTHOR = author
    }

    for _, file_name in ipairs(selected.files) do
        local file_url = RAW_BASE_URL .. selected.name .. "/" .. file_name
        show_spinner(0.4, "Downloading " .. file_name .. "...")
        
        local content = http_get(file_url)
        if content then
            local processed = replace_placeholders(content, data)
            if write_file(file_name, processed) then
                print(COLORS.GREEN .. "  ✔ " .. COLORS.RESET .. file_name)
            else
                print(COLORS.RED .. "  ✖ " .. COLORS.RESET .. "Failed to write " .. file_name)
            end
        else
            print(COLORS.RED .. "  ✖ " .. COLORS.RESET .. "Failed to download " .. file_name)
        end
    end

    print("\n" .. COLORS.GREEN .. COLORS.BOLD .. "Done!" .. COLORS.RESET .. " Your extension is ready in " .. COLORS.BOLD .. "./" .. COLORS.RESET)
end

local function show_help()
    print(COLORS.BOLD .. "extify" .. COLORS.RESET .. " - Browser Extension Boilerplate Generator")
    print("\nUsage:")
    print("  extify init      Initialize a new extension in the current directory")
    print("  extify help      Show this help message")
end

local args = {...}
local command = args[1]

if command == "init" then
    init_project()
elseif command == "help" or not command then
    show_help()
else
    color_print(COLORS.RED, "Unknown command: " .. command)
    show_help()
end

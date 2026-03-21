local args = {...}

local command = args[1]
local name = args[2]

if command == "create" then
  local file = io.open("hello.txt","a")
    if file ~= nil then
      file:write("\nHello " .. name)
      file:close()
    else
      print("Could not open the file")
    end
else
  print("Command not found, run extify help for more info")
end

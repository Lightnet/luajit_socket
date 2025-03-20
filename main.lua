-- main.lua
local function check_versions()
  -- Check LuaJIT version
  local lua_version = _VERSION or "unknown"
  local jit_version = jit and jit.version or "not LuaJIT"
  print("Lua version: " .. lua_version)
  print("JIT version: " .. jit_version)

  -- Check LuaSocket version
  local socket = package.loaded.socket or require('socket')
  if not socket then
      error("Failed to load socket module")
  end
  local socket_version = socket._VERSION or "unknown"
  print("LuaSocket version: " .. socket_version)

  return socket  -- Return socket for use in the test
end

local function run_test(socket)
  -- Create TCP socket
  local tcp = socket.tcp()
  if not tcp then
      error("Failed to create TCP socket")
  end

  -- Connect to example.com
  local ok, err = tcp:connect('example.com', 80)
  if not ok then
      tcp:close()
      error("Failed to connect: " .. (err or "unknown error"))
  end

  -- Send HTTP request
  local sent, err = tcp:send('GET / HTTP/1.0\r\nHost: example.com\r\n\r\n')
  if not sent then
      tcp:close()
      error("Failed to send request: " .. (err or "unknown error"))
  end

  -- Receive response
  local response, err = tcp:receive('*a')
  if not response then
      tcp:close()
      error("Failed to receive response: " .. (err or "unknown error"))
  end

  -- Print truncated response
  print('Response received: ' .. response:sub(1, 100) .. '...')

  -- Clean up
  tcp:close()
end

-- Run with error handling
local status, err = pcall(function()
  local socket = check_versions()
  run_test(socket)
end)
if not status then
  print("Error: " .. err)
  os.exit(1)
end
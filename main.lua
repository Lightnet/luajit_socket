-- main.lua
local function run_test()
  -- Check if socket module is available
  local socket = package.loaded.socket or require('socket')
  if not socket then
      error("Failed to load socket module")
  end

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
local status, err = pcall(run_test)
if not status then
  print("Error: " .. err)
  os.exit(1)
end
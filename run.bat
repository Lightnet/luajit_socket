@echo off
@REM if not exist build mkdir build
cd build
@REM echo Copying current main.lua to build\Debug folder...
copy ..\main.lua main.lua
echo Running LuaSocketTest
@REM cd Debug
LuaSocketTest.exe main.lua
@REM pause
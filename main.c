#include <stdio.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main() {
    lua_State *L = luaL_newstate();
    if (!L) {
        fprintf(stderr, "Failed to create Lua state\n");
        return 1;
    }

    luaL_openlibs(L);  // Open standard libraries, including package

    // Load main.lua from file
    if (luaL_loadfile(L, "main.lua") != LUA_OK) {
        fprintf(stderr, "Error loading main.lua: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        lua_close(L);
        return 1;
    }

    // Execute the loaded script
    if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
        fprintf(stderr, "Error running main.lua: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        lua_close(L);
        return 1;
    }

    lua_close(L);
    printf("Script executed successfully.\n");
    return 0;
}
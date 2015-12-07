set -e

# target directory for Lua/LuaRocks/...
D="$HOME/programs"

tgz_download() {
  curl -s -S --location "$1" | tar xz
}


install_lua() {
  tgz_download http://www.lua.org/ftp/lua-"$1".tar.gz
  (cd lua-"$1" && \
    make "$2" && \
    make install INSTALL_TOP="$D")
}


install_luarocks() {
  tgz_download http://luarocks.org/releases/luarocks-"$1".tar.gz
  (cd luarocks-"$1" && \
    ./configure --prefix="$D" --with-lua="$D" --force-config && \
    make bootstrap)
}


# detect which make target to use to build Lua
case `uname -s` in
  Linux) LUA_MAKE_TARGET=linux ;;
  Darwin) LUA_MAKE_TARGET=macosx ;;
  *) echo "unsupported system" >&2; false ;;
esac

# make sure that the LUA variable is set
test -n "$LUA"
# create base directory if it doesn't exist
[ -d "$D" ] || mkdir -p "$D"

# download and install the requested Lua interpreter
(cd "$D" && install_lua "$LUA" "$LUA_MAKE_TARGET")

# download and install LuaRocks (if requested)
[ -z "$LUAROCKS" ] || (cd "$D" && install_luarocks "$LUAROCKS")

# setup LUA_PATH, LUA_CPATH, and PATH for Lua and LuaRocks
export PATH="$D/bin:$PATH"
[ -z "$LUAROCKS" ] || eval `luarocks path`


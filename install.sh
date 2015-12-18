set -e -o pipefail

# target directory for Lua/LuaRocks/...
D="$HOME/programs"


tgz_download() {
  curl --fail --silent --show-error --location "$1" | tar xz
}


install_lua() {
  tgz_download http://www.lua.org/ftp/lua-"$1".tar.gz
  case "`uname -s`" in
    Linux) local LUA_MAKE_TARGET=linux ;;
    Darwin) local LUA_MAKE_TARGET=macosx ;;
    *) echo "unsupported system" >&2; return 1 ;;
  esac
  (cd lua-"$1" && \
    make "$LUA_MAKE_TARGET" && \
    make install INSTALL_TOP="$D")
}


install_luajit() {
  tgz_download http://luajit.org/download/LuaJIT-"$1".tar.gz
  (cd LuaJIT-"$1" && \
    make PREFIX="$D" && \
    make install PREFIX="$D")
  ln -sf luajit "$D/bin/lua"
  (cd "$D"/include && find luajit-* -name "*.h*" -exec ln -sf {} . \;)
}


install_luarocks() {
  tgz_download http://luarocks.org/releases/luarocks-"$1".tar.gz
  (cd luarocks-"$1" && \
    ./configure --prefix="$D" --with-lua="$D" --force-config && \
    make bootstrap)
}


# create base directory if it doesn't exist
[ -d "$D" ] || mkdir -p "$D"
# make sure that the LUA variable is set
[ -n "$LUA" ] || LUA=5.3.2
# download and install the requested Lua interpreter
case "$LUA" in
  [Ll]ua[Jj][Ii][Tt][0123456789]*.*)
    (cd "$D" && install_luajit "${LUA#??????}") ;;
  [Ll]ua[0123456789]*.*)
    (cd "$D" && install_lua "${LUA#???}") ;;
  [0123456789]*.*)
    (cd "$D" && install_lua "$LUA") ;;
  *)
    echo "invalid Lua version: $LUA" >&2; false ;;
esac

# download and install LuaRocks (if requested)
[ -z "$LUAROCKS" ] || (cd "$D" && install_luarocks "$LUAROCKS")

# setup LUA_PATH, LUA_CPATH, and PATH for Lua and LuaRocks
export PATH="$D/bin:$PATH"
[ -z "$LUAROCKS" ] || eval "`luarocks path`"

# restore shell options
set +e +o pipefail


package = "cparser"
version = "scm-1"
source = {
  url = "git://github.com/AbigailBuccaneer/cparser.lua",
}
description = {
  summary = "A C parser",
  license = "MIT",
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["cparser.backtrackingstream"] = "cparser/backtrackingstream.lua",
    ["cparser.charstream"] = "cparser/charstream.lua",
    ["cparser.declarations"] = "cparser/declarations.lua",
    ["cparser.lexer"] = "cparser/lexer.lua",
    ["cparser.lexrule"] = "cparser/lexrule.lua",
    ["cparser.retokenizer"] = "cparser/retokenizer.lua",
  }
}

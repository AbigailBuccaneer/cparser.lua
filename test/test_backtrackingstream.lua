local L = require "luaunit"
local BacktrackingStream = require "cparser.backtrackingstream"
local Lexer = require "cparser.lexer"

function test_backtrackingstream_forward()
  local source = [[int main(int argc, int **argv) { /* cool stuff goes here */ return 0xFFF - int(argc); }]]
  local lexer = Lexer.new(source)
  local backtracker = BacktrackingStream.new(Lexer.new(source))

  while true do
    local lexed = lexer:nextToken()
    local backtracked = backtracker:nextToken()
    L.assertEquals(lexed, backtracked)
    if lexed == nil or backtracked == nil then return nil end
  end
end

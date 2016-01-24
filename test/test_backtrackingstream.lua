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

function test_backtrackingstream_forward_eof()
  local stream = BacktrackingStream.new(Lexer.new(""))
  local pos = stream:pos()
  L.assertEquals(stream:nextToken(), nil)
  L.assertEquals(stream:pos(), pos)
end

function test_backtrackingstream_peek()
  local source = [[int x = 0xFF /* foo bar */;]]
  local stream = BacktrackingStream.new(Lexer.new(source))
  while true do
    local a = stream:peekToken()
    local b = stream:peekToken()
    local c = stream:nextToken()
    L.assertEquals(a, b)
    L.assertEquals(b, c)
    if (a or b or c) == nil then return nil end
  end
end

function test_backtrackingstream_peek_eof()
  local stream = BacktrackingStream.new(Lexer.new(""))
  L.assertEquals(stream:peekToken(), nil)
end

function test_backtrackingstream_backtrack()
  local source = [[int x = 0xFF;]]
  local stream = BacktrackingStream.new(Lexer.new(source))
  local a_pos = stream:pos()
  local a = stream:nextToken()
  local b = stream:nextToken()
  local c_pos = stream:pos()
  local c = stream:nextToken()
  stream:backtrack(a_pos)
  L.assertEquals(a, stream:peekToken())
  stream:backtrack(c_pos)
  L.assertEquals(c, stream:peekToken())
end

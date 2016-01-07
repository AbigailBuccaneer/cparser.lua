local L = require "luaunit"
local CharStream = require "cparser.charstream"

function test_charstream_walk()
  local self = CharStream.new("abcd")
  L.assertFalse(self:eof())
  L.assertEquals(self:peek(), "a")
  L.assertEquals(self:advance(), "a")

  L.assertFalse(self:eof())
  L.assertEquals(self:peek(), "b")
  L.assertEquals(self:advance(), "b")

  L.assertFalse(self:eof())
  L.assertEquals(self:peek(), "c")
  L.assertEquals(self:advance(), "c")

  L.assertFalse(self:eof())
  L.assertEquals(self:peek(), "d")
  L.assertEquals(self:advance(), "d")

  L.assertTrue(self:eof())
  L.assertNil(self:peek())
  L.assertNil(self:advance())
end

function test_charstream_backtrack()
  local self = CharStream.new("abc")

  local pos = self:pos()
  L.assertEquals(self:advance(), "a")
  L.assertEquals(self:advance(), "b")
  L.assertEquals(self:advance(), "c")
  L.assertTrue(self:eof())

  self:backtrack(pos)
  L.assertEquals(self:pos(), pos)
  L.assertFalse(self:eof())
  L.assertEquals(self:advance(), "a")
end

function dont_test_charstream_newline()
  -- each of these should be recognised as containing exactly one newline
  local tests = { "ab\ncd", "ab\rcd", "ab\r\ncd", "ab\n\rcd" }
  for _, test in pairs(tests) do
    local stream = CharStream.new(test)
    while not stream:eof() do stream:advance() end
    L.assertEquals(stream.Position.Line, 2)
  end
end

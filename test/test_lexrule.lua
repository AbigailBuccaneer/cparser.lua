local LexRule = require "cparser.lexrule"
local CharStream = require "cparser.charstream"
local L = require "luaunit"

function test_lexrule_new()
  local stream = CharStream.new("abcdef")

  -- check that we can make rules with either LexRule.new(...) or LexRule(...)
  for _, initializer in pairs{ LexRule.new, LexRule } do
    -- and that it works for strings and functions
    for _, testcase in pairs{ function() return true end, "foo" } do
      local rule = initializer(testcase)
      -- check that it can be applied to a stream
      L.assertIsBoolean(rule(stream))
    end
  end

  L.assertError(LexRule.new)
  L.assertError(LexRule.new, {})
end

function test_lexrule_any()
  local stream = CharStream.new("abcdef")
  L.assertTrue(LexRule.any(stream))
  L.assertEquals(stream:peek(), 'b')
end

function test_lexrule_class()
  local stream = CharStream.new("aobcdef")
  local vowels = LexRule.class('a', 'e', 'i', 'o', 'u')
  L.assertTrue(vowels(stream))
  L.assertEquals(stream:peek(), 'o')
  L.assertTrue(vowels(stream))
  L.assertEquals(stream:peek(), 'b')
  L.assertFalse(vowels(stream))

  local abc = LexRule.class('a-c')
  L.assertTrue(abc(stream))
  L.assertEquals(stream:peek(), 'c')
  L.assertTrue(abc(stream))
  L.assertEquals(stream:peek(), 'd')
  L.assertFalse(abc(stream))

  local abcd = LexRule.class(abc, 'd')
  L.assertTrue(abcd(stream))
  L.assertEquals(stream:peek(), 'e')

  local ef = LexRule.class('f', LexRule.class('e'))
  L.assertTrue(ef(stream))
  L.assertEquals(stream:peek(), 'f')

  L.assertError(LexRule.class, "ab")
  L.assertError(LexRule.class, {})
end

function test_lexrule_string()
  local stream = CharStream.new("abcdef")
  L.assertTrue(LexRule.string('a')(stream))
  L.assertEquals(stream:peek(), 'b')

  L.assertFalse(LexRule.string('a')(stream))
  L.assertEquals(stream:peek(), 'b')

  L.assertTrue(LexRule.string("bc")(stream))
  L.assertEquals(stream:peek(), 'd')

  L.assertFalse(LexRule.string("ed")(stream))
  L.assertEquals(stream:peek(), 'd')

  L.assertError(LexRule.string)
  L.assertError(LexRule.string, {})
end

function test_lexrule_negate()
  local stream = CharStream.new("abcdef")
  L.assertTrue((-LexRule'b')(stream))
  L.assertEquals(stream:peek(), 'a')

  L.assertFalse((-LexRule'a')(stream))
  L.assertEquals(stream:peek(), 'a')
end

function test_lexrule_concat()
  local stream = CharStream.new("abcdef")

  L.assertTrue((LexRule.string('a') .. LexRule.string('b'))(stream))
  L.assertEquals(stream:peek(), 'c')

  L.assertFalse((LexRule.string('b') .. LexRule.string('b'))(stream))
  L.assertEquals(stream:peek(), 'c')

  L.assertFalse((LexRule.string('c') .. LexRule.string('c'))(stream))
  L.assertEquals(stream:peek(), 'c')
end

function test_lexrule_either()
  local stream = CharStream.new("abcdef")
  L.assertTrue((LexRule'a' / LexRule"bc")(stream))
  L.assertEquals(stream:peek(), 'b')

  L.assertTrue((LexRule"bb" / LexRule'b')(stream))
  L.assertEquals(stream:peek(), 'c')

  L.assertFalse((LexRule'd' / LexRule'b')(stream))
  L.assertEquals(stream:peek(), 'c')
end


function test_lexrule_many()
  local stream = CharStream.new("abcdef")
  L.assertTrue(LexRule.many(LexRule'x')(stream))
  L.assertEquals(stream:peek(), 'a')
  L.assertTrue(LexRule.many(LexRule'ab')(stream))
  L.assertEquals(stream:peek(), 'c')
  L.assertTrue(LexRule.many(LexRule.class('c-e'))(stream))
  L.assertEquals(stream:peek(), 'f')
end

function test_lexrule_optional()
  local stream = CharStream.new("abcdef")
  L.assertTrue(LexRule.optional(LexRule"abc")(stream))
  L.assertEquals(stream:peek(), 'd')
  L.assertTrue(LexRule.optional(LexRule"abc")(stream))
  L.assertEquals(stream:peek(), 'd')
end

function test_lexrule_repetition()
  local stream = CharStream.new("aaaaaaaa!")
  L.assertTrue((LexRule'a' ^ { 1 })(stream))
  L.assertEquals(stream.Offset, 2)

  L.assertTrue((LexRule'a' ^ 2)(stream))
  L.assertEquals(stream.Offset, 4)

  L.assertTrue((LexRule'a' ^ { 0, 1})(stream))
  L.assertEquals(stream.Offset, 5)

  L.assertTrue((LexRule'a' ^ { 1, 5 })(stream))
  L.assertEquals(stream.Offset, 9)

  L.assertFalse((LexRule'a' ^ 2)(stream))

  L.assertError(LexRule.metatable.__pow, LexRule'a', { 3, 2 })
  L.assertError(LexRule.metatable.__pow, LexRule'a', -1)

  L.assertError(LexRule.metatable.__pow, LexRule'a', { 1, 2, 3 })

  local dodgyTable = setmetatable({}, { __len = function() return 1 end })
  L.assertError(LexRule.metatable.__pow, LexRule'a', dodgyTable)
end

function test_lexrule_subtract()
  local stream = CharStream.new("/* comment */!code;")
  local blockComment = LexRule'/*' .. LexRule.many(LexRule.any - LexRule'*/') .. LexRule'*/'
  L.assertTrue(blockComment(stream))
  L.assertEquals(stream:peek(), '!')

  local unterminated = LexRule.many(LexRule.any - LexRule'X')
  L.assertTrue(unterminated(stream))
  L.assertTrue(stream:eof())
end

local L = require "luaunit"
local Lexer = require "cparser.lexer"
local Retokenizer = require "cparser.retokenizer"

local function ident(str) return { Type = "identifier", Text = str } end
local function number(str) return { Type = "pp-number", Text = str } end
local function punc(str) return { Type = "punctuator", Text = str } end
local function char(str) return { Type = "character-constant", Text = str } end
local function string(str) return { Type = "string-literal", Text = str } end

local function stream(...)
  local tokens = {}
  for i = 1, select('#', ...) do table.insert(tokens, (select(i, ...))) end
  tokens.nextToken = function(self) return table.remove(self, 1) end
  return tokens
end

function test_retokenizer_keywords()
  local stream1 = Retokenizer.new(stream(ident"i", ident"int", ident"intellectual",
                         ident"While", ident"while", ident"while1"))
  L.assertEquals(stream1:nextToken().Type, "identifier")
  L.assertEquals(stream1:nextToken().Type, "keyword")
  L.assertEquals(stream1:nextToken().Type, "identifier")
  L.assertEquals(stream1:nextToken().Type, "identifier")
  L.assertEquals(stream1:nextToken().Type, "keyword")
  L.assertEquals(stream1:nextToken().Type, "identifier")
end

function test_retokenizer_punctuator()
  local source = "{..}[...]>>=>>>|||!"
  local split = { "{", ".", ".", "}", "[", "...", "]", ">>=", ">>", ">", "||", "|", "!" }
  local stream = Retokenizer.new(Lexer.new(source))
  for _, expectedText in ipairs(split) do
    local token = stream:nextToken()
    L.assertTrue(token)
    L.assertEquals(token.Type, "punctuator")
    L.assertEquals(token.Text, expectedText)
  end
end

function test_retokenizer_number()
  local source = "0xFFF 0377 678.475 .3e10"
  local split = { "0xFFF", "0377", "678.475", ".3e10" }
  local stream1 = Retokenizer.new(Lexer.new(source))
  for _, expectedText in ipairs(split) do
    local token = stream1:nextToken()
    L.assertEquals(token.Type, "number")
    L.assertEquals(token.Text, expectedText)
    L.assertNotNil(token.ExpressionType)
  end

  local source = "0379 0.a 1.2.3 0xGG"
  local stream2 = Retokenizer.new(Lexer.new(source))
  for _, expectedText in ipairs(split) do
    L.assertError(stream2.nextToken, stream)
  end

  local stream3 = Retokenizer.new(stream(number("this isn't a number, how'd this get lexed as a number")))
  L.assertError(stream3.nextToken, stream)
end

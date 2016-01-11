local R = require "cparser.lexrule"
local CharStream = require "cparser.charstream"

local Lexer = {}
Lexer.__index = Lexer

function Lexer.new(text)
  local self = setmetatable({}, Lexer)
  self.Stream = CharStream.new(text)
  self.logicalWhitespace(self.Stream)
  return self
end

local newline = R.class('\r', '\n')
local whitespace = R.class(' ', '\t', '\n', '\v', '\f', '\r')

local lineComment = R"//" .. R.many((-newline) .. R.any)
local blockComment = R"/*" .. R.many(R.any - R'*/') .. R"*/"

Lexer.logicalWhitespace = R.many(whitespace / lineComment / blockComment)

local letter = R.class('A-Z', 'a-z')
local digit = R.class('0-9')

Lexer.identifier = R.class(letter, '_') .. R.many(R.class(letter, digit, '_'))

Lexer.number = R.optional(R'.') .. digit .. R.many(
  R.class(digit, '.') /
  (R.class('e', 'E', 'p', 'P') .. R.class('+', '-')) /
  Lexer.identifier
)

local escapeSequence = R'\\' .. (
  R.class("'", '"', '?', '\\', 'a', 'b', 'f', 'n', 'r', 't', 'v') /
  (R'x' .. R.many(R.class(digit, 'A-F', 'a-f'))) /
  (R.class('0-7') ^ { 1, 3 })
)

Lexer.characterConstant = R.optional(R.class('L', 'u', 'U')) .. R"'" ..
  R.many((R.any - R.class("'", '\\', newline)) / escapeSequence) .. R"'"

Lexer.stringLiteral = R.optional(R"u8" / R.class('L', 'u', 'U')) .. R'"' ..
  R.many((R.any - R.class('"', '\\', newline)) / escapeSequence) .. R'"'

-- For efficiency, we turn all the punctuators into one big trie. (This won't
-- be necessary if/when lexrules are turned into DFAs, like lex/flex do.)
local punctuators = {
  "[", "]", "(", ")", "{", "}", ".", "->", "++", "--", "&", "*", "+", "-", "~",
  "!", "/", "%", "<<", ">>", "<", ">", "<=", ">=", "==", "!=", "^", "|", "&&",
  "||", "?", ":", ";", "...", "=", "*=", "/=", "%=", "+=", "-=", "<<=", ">>=",
  "&=", "^=", "|=", ",", "#", "##", "<:", ":>", "<%", "%>", "%:", "%:%:",
}

local trie = {}

for _, punctuator in pairs(punctuators) do
  local node = trie
  for i = 1, #punctuator do
    local char = string.sub(punctuator, i, i)
    if not node[char] then node[char] = {} end
    node = node[char]
  end
  node.valid = true
end

Lexer.punctuator = R.new(function(stream)
  local node = trie
  local pos = stream:pos()
  local valid = false
  while true do
    if node.valid then pos = stream:pos() valid = true end
    if stream:eof() then break end
    node = node[stream:peek()]
    if not node then break end
    stream:advance()
  end
  stream:backtrack(pos)
  return valid
end)

function Lexer:nextToken()
  if self.Stream:eof() then return nil end
  -- a token contains positional information about where in the stream it
  -- starts, so we use that table as the basis for a token
  local token = self.Stream:pos()
  token.Type = "other"

  if self.characterConstant(self.Stream) then
    token.Type = "character-constant"
  elseif self.stringLiteral(self.Stream) then
    token.Type = "string-literal"
  elseif self.number(self.Stream) then
    token.Type = "pp-number"
  elseif self.identifier(self.Stream) then
    token.Type = "identifier"
  elseif self.punctuator(self.Stream) then
    token.Type = "punctuator"
  else
    self.Stream:advance()
  end

  token.Text = string.sub(self.Stream.Text, token.Offset, self.Stream.Offset - 1)

  self.logicalWhitespace(self.Stream)

  return token
end

return Lexer

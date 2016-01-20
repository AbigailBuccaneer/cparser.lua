--- Retokenize preprocessing tokens into C tokens
-- The tokens produced by lexer.lua are 'preprocessing tokens' - they're what
-- the C preprocessor takes as input. In particular, the C preprocessor
-- doesn't care about keywords, and has an overly-simplistic definition of
-- a number in order to make token pasting more flexible.
-- This is where we turn those preprocessing tokens into C tokens, and parse
-- contents of token text (eg. deduce the value and type of numbers).
--
-- The possible resultant output types are:
-- * identifier
-- * keyword (with the field .Keyword containing the name of the keyword)
-- * punctuator (with the field .Punctuation containing the represented punctuation)
-- * integer-constant
-- * floating-constant
-- * character-constant
-- * string-literal

local R = require "cparser.lexrule"
local CharStream = require "cparser.charstream"

local Retokenizer = {}

--- Construct a new retokenizer around an existing token stream.
function Retokenizer.new(tokenStream)
  return setmetatable({ Stream = tokenStream }, { __index = Retokenizer })
end

local keywords = {
  "auto", "break", "case", "char", "const", "continue", "default", "do",
  "double", "else", "enum", "extern", "float", "for", "goto", "if", "inline",
  "int", "long", "register", "restrict", "return", "short", "signed", "sizeof",
  "static", "struct", "switch", "typedef", "union", "unsigned", "void",
  "volatile", "while", "_Alignas", "_Alignof", "_Atomic", "_Bool", "_Complex",
  "_Generic", "_Imaginary", "_Noreturn", "_Static_assert", "_Thread_local",
}
local keyword_lookup = {}
for _, v in pairs(keywords) do keyword_lookup[v] = true end

local digraphs = {
  ["<:"] = "[",
  [":>"] = "]",
  ["<%"] = "{",
  ["%>"] = "}",
  ["%:"] = "#",
  ["%:%:"] = "##",
}

local digit = R.class('0-9')
local hexDigit = R.class(digit, 'A-F', 'a-f')
local hexadecimalPrefix = R'0' .. R.class('x', 'X')
local octalDigit = R.class('0-7')

local decimalConstant = (digit - R'0') .. R.many(digit)
local octalConstant = R'0' .. R.many(octalDigit)
local hexadecimalConstant = (hexadecimalPrefix .. R.many(hexDigit))
local longSuffix = (R'l' ^ { 1, 2 }) / (R'L' ^ { 1, 2 })
local unsignedSuffix = R.class('u', 'U')
local integerSuffix = (unsignedSuffix .. R.optional(longSuffix)) / (longSuffix .. R.optional(unsignedSuffix))
local integerConstant = (hexadecimalConstant / octalConstant / decimalConstant) .. R.optional(integerSuffix)

local digitSequence = digit .. R.many(digit)
local exponentPart = R.class('e', 'E') .. R.optional(R.class('+', '-')) .. digitSequence
local fractionalConstant = (R.optional(digitSequence) .. R'.' .. digitSequence) / (digitSequence .. R'.')
local decimalFloatingConstant = (fractionalConstant .. R.optional(exponentPart)) / (digitSequence .. exponentPart)

local hexadecimalDigitSequence = hexDigit .. R.many(hexDigit)
local hexadecimalFractionalConstant = (R.many(hexDigit) .. R'.' .. hexadecimalDigitSequence) / (hexadecimalDigitSequence .. R'.')
local binaryExponentPart = R.class('p', 'P') .. R.optional(R.class('+', '-')) .. digitSequence
local hexadecimalFloatingConstant = hexadecimalPrefix .. (hexadecimalFractionalConstant / hexadecimalDigitSequence) .. binaryExponentPart

local floatingConstant = (decimalFloatingConstant / hexadecimalFloatingConstant) .. R.optional(R.class('f', 'F', 'l', 'L'))



--- Take the next token in the underlying token stream, process it and return it.
function Retokenizer:nextToken()
  local token = self.Stream:nextToken()
  if token == nil then return nil end

  if token.Type == "identifier" and keyword_lookup[token.Text] then
    token.Type = "keyword"
    token.Keyword = token.Text
  elseif token.Type == "punctuator" then
    token.Punctuation = digraphs[token.Text] or token.Text
  elseif token.Type == "pp-number" then
    local number = CharStream.new(token.Text)
    if floatingConstant(number) then
      assert(number:eof(), "invalid floating point number " .. token.Text)
      token.Type = "floating-constant"
    elseif integerConstant(number) then
      assert(number:eof(), "invalid integer " .. token.Text)
      token.Type = "integer-constant"
    else
      -- This should never happen - anything lexed as a pp-number starts with
      -- either 'digit' or '.digit' so either floatingConstant or integerConstant
      -- would match a prefix (and then give the error, invalid float/int above)
      error("invalid numeric constant " .. token.Text)
    end
  end
  return token
end

return Retokenizer

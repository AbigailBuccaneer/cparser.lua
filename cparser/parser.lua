local BacktrackingStream = require "cparser.backtrackingstream"
local Retokenizer = require "cparser.retokenizer"
local Lexer = require "cparser.lexer"
local Declarations = require "cparser.declarations"

local Parser = {}
Parser.__index = Parser

function Parser.new(source)
  local self = setmetatable({}, Parser)
  self.stream = BacktrackingStream.new(Retokenizer.new(Lexer.new(source)))
  self.declarations = Declarations.new()
  return self
end

function Parser:peekToken()
  local token = self.stream:peekToken()
  if token.Type == "identifier" then
    token.Type = self.declarations:find(token.Text)
  end
  return token
end

function Parser:nextToken()
  self:peekToken() -- for the side-effect of retyping it according to declarations
  return self.stream:nextToken()
end

function Parser:pos() return self.stream.pos end
function Parser:backtrack(pos) return self.stream:backtrack(pos) end

function Parser:matchToken(tokenSpec)
  local token = self:peekToken()
  if token == nil then return nil end
  for k, v in pairs(tokenSpec) do
    if token[k] ~= v then return nil end
  end
  return self:nextToken()
end

function Parser:identifier() return self:matchToken{ Type = "identifier" } end
function Parser:keyword(keyword) return self:matchToken{ Type = "keyword", Keyword = keyword } end
function Parser:punctuator(punctuation) return self:matchToken{ Type = "punctuator", Punctuation = punctuation } end

function Parser:constant()
  local constant =
  parser:matchToken{ Type = "integer-constant" } or
    parser:matchToken{ Type = "floating-constant" } or
    parser:matchToken{ Type = "enumeration-constant" } or
    parser:matchToken{ Type = "character-constant" }

  if constant then return { Type = "constant", constant } end
end

function Parser:stringLiteral() return self:matchToken{ Type = "string-literal" } end

return Parser

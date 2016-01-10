local Lexer = require "cparser.lexer"
local L = require "luaunit"

function test_lexer_preceding_whitespace()
  local lexer = Lexer.new("  \n  !")
  L.assertEquals(lexer.Stream:peek(), "!")
  lexer = Lexer.new("/* this is a cool block/ comment*/!")
  L.assertEquals(lexer.Stream:peek(), "!")
end

function test_lexer_number()
  local lexer = Lexer.new[[147849!]]
  L.assertTrue(lexer.number(lexer.Stream))
  L.assertEquals(lexer.Stream:peek(), "!")
end

function test_lexer_identifier()
  local testcases = {
    "woof!",
    "Woof!",
    "WOOF!",
    "K9K9K9!",
  }
  for _, testcase in pairs(testcases) do
    local lexer = Lexer.new(testcase)
    L.assertTrue(lexer.identifier(lexer.Stream))
    L.assertEquals(lexer.Stream:peek(), "!")
  end
end

function test_lexer_character_constant()
  local testcases = {
    [['a']],
    [['!']],
    [['\'']],
    [['\123']],
    [['\x10FFFF']],
    [['\n']],
    [['abcd']],
  }

  for _, testcase in pairs(testcases) do
    local lexer = Lexer.new(testcase)
    L.assertTrue(lexer.characterConstant(lexer.Stream))
    L.assertTrue(lexer.Stream:eof())
  end

  testcases = {
    [['a]],
    "'\n'",
  }
  for _, testcase in pairs(testcases) do
    local lexer = Lexer.new(testcase)
    L.assertFalse(lexer.characterConstant(lexer.Stream))
  end
end

function test_lexer_string_constant()
  local testcases = {
    [["foo! bar baz"]],
    [["foo\nbar"]],
  }

  for _, testcase in pairs(testcases) do
    local lexer = Lexer.new(testcase)
    L.assertTrue(lexer.stringLiteral(lexer.Stream))
    L.assertTrue(lexer.Stream:eof())
  end
end

function test_lexer_punctuator()
  local lexer = Lexer.new(",,")
  L.assertTrue(lexer.punctuator(lexer.Stream))
  L.assertEquals(lexer.Stream.Offset, 2)
end

function test_lexer_program()
  local program = [[
// this is a short program designed to /* test the lexer */ for bugs
/* it should all run
// okay, right?
*/

int main(int argc, char **argv) {
  char* buffer = "mashed\npotatoes!\xAA\x55";

  int x = foo();
  x++;
  x = (x < 0xFF) ? x + 0777 : x - buffer['\n'];
  return x;
}
]]

  local function ident(x) return { Type = "identifier", Text = x } end
  local function punc(x) return { Type = "punctuator", Text = x } end
  local function number(x) return { Type = "pp-number", Text = x } end
  local function char(x) return { Type = "character-constant", Text = x } end
  local function string(x) return { Type = "string-literal", Text = x } end

  local tokens = {
    ident"int", ident"main", punc"(", ident"int", ident"argc", punc",", ident"char", punc"*", punc"*", ident"argv", punc")", punc"{",
    ident"char", punc"*", ident"buffer", punc"=", string[["mashed\npotatoes!\xAA\x55"]], punc";",
    ident"int", ident"x", punc"=", ident"foo", punc"(", punc")", punc";",
    ident"x", punc"++", punc";",
    ident"x", punc"=", punc"(", ident"x", punc"<", number"0xFF", punc")", punc"?", ident"x", punc"+", number"0777",
    punc":", ident"x", punc"-", ident"buffer", punc"[", char[['\n']], punc"]", punc";",
    ident"return", ident"x", punc";",
    punc"}"
  }

  local lexer = Lexer.new(program)
  for _, token in ipairs(tokens) do
    local lexedToken = lexer:nextToken()
    L.assertEquals(lexedToken.Type, token.Type)
    L.assertEquals(lexedToken.Text, token.Text)
  end

end

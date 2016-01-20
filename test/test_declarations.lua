local L = require "luaunit"
local Declarations = require "cparser.declarations"

function test_declarations_push_pop()
  local decls = Declarations.new()
  L.assertError(decls.popScope, decls)
  decls:pushScope()
  decls:popScope()
  L.assertError(decls.popScope, decls)
  decls:pushScope()
  decls:pushScope()
  decls:popScope()
  decls:popScope()
  L.assertError(decls.popScope, decls)
end

function test_declarations_redefine()
  local decls = Declarations.new()

  L.assertEquals(decls:find("test"), "identifier")

  decls:addDeclaration("my_int_type", "typedef-name")
  L.assertEquals(decls:find("my_int_type"), "typedef-name")

  decls:pushScope()
  L.assertEquals(decls:find("my_int_type"), "typedef-name")
  decls:addDeclaration("my_int_type", "identifier") -- shadow the declaration
  L.assertEquals(decls:find("my_int_type"), "identifier")
  decls:pushScope()
  L.assertEquals(decls:find("my_int_type"), "identifier")
  decls:popScope()
  decls:popScope()
end

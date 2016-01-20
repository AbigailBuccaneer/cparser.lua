--- Tracks declarations as necessary for parsing
-- C is an ambiguous grammar: The expression "(T) *x" is either a cast of a
-- dereference or a multiplication of two identifiers, depending on whether
-- T is a type name or not. In order to deal with this ambiguity, we keep
-- track of all the defined names in all the current scopes.

local Declarations = {}
Declarations.__index = Declarations

function Declarations.new()
  local self = setmetatable({}, Declarations)
  self.scopes = { {} }
  return self
end

function Declarations:pushScope()
  table.insert(self.scopes, {})
end

function Declarations:popScope()
  assert(#self.scopes > 1, "attempting to pop global scope")
  table.remove(self.scopes)
end

function Declarations:addDeclaration(name, type)
  self.scopes[#self.scopes][name] = type
end

function Declarations:find(name)
  for i = #self.scopes, 1, -1 do
    local type = self.scopes[i][name]
    if type then return type end
  end
  return "identifier"
end

return Declarations

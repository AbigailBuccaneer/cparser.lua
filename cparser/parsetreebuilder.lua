--- A convenient interface for turning a token stream into a parse tree

local ParseTreeBuilder = {}
ParseTreeBuilder.__index = ParseTreeBuilder

function ParseTreeBuilder.new(stream)
  local self = setmetatable({}, ParseTreeBuilder)
  self.Stream = stream
  self.TokensAhead = { stream:nextToken() }
  self.Node = nil
  return self
end

function ParseTreeBuilder:mark()
  local leaf = { Parent = self.Node }
  self.Node = leaf
end

function ParseTreeBuilder:done(type)
  local child = self.Node
  child.Type = type
  self.Node = child.Parent
  child.Parent = nil
  table.insert(self.Node, child)
  return child
end

function ParseTreeBuilder:drop()
  local marker = self.Node
  for i = 1, #marker do table.insert(self.TokensAhead, marker[i]) end
  self.Node = marker.Parent
end

function ParseTreeBuilder:error(message)
  self.Node.Message = message
  self:done("error")
end

function ParseTreeBuilder:consumeToken()
  table.insert(self.Node, table.remove(self.TokensAhead, 1))
  if #self.TokensAhead == 0 then self.TokensAhead[1] = self.Stream:nextToken() end
end

function ParseTreeBuilder:token()
  return self.TokensAhead[1]
end

return ParseTreeBuilder

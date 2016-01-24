--- Adds backtracking to an underlying stream of tokens

local BacktrackingStream = {}
BacktrackingStream.__index = BacktrackingStream

function BacktrackingStream.new(stream)
  local self = setmetatable({}, BacktrackingStream)
  self.stream = stream
  self.tokens = {}
  self.offset = 1
  return self
end

function BacktrackingStream:pos()
  return self.offset
end

function BacktrackingStream:backtrack(pos)
  self.offset = pos
end

function BacktrackingStream:nextToken()
  local nextToken = self:peekToken()
  if nextToken ~= nil then self.offset = self.offset + 1 end
  return nextToken
end

function BacktrackingStream:peekToken()
  while self.offset > #self.tokens do
    local token = self.stream:nextToken()
    if not token then return end
    table.insert(self.tokens, token)
  end
  return self.tokens[self.offset]
end

return BacktrackingStream

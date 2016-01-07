--- A stream that allows character-by-character traversal of a string,
-- including backtracking and position information.
-- @classmod CharStream
local CharStream = {}

--- Construct a new CharStream at the beginning of the given text.
function CharStream.new(text)
  local self = setmetatable({}, { __index = CharStream })
  self.Text = assert(text)
  self.Offset = 1
  self.Position = { Line = 1, Col = 1 }
  return self
end

--- @return whether we've reached the end of the stream.
function CharStream:eof()
  return self.Offset > #self.Text
end

--- @return the character at the current point in the stream.
function CharStream:peek()
  if self:eof() then return end
  return string.sub(self.Text, self.Offset, self.Offset)
end

--- Advance one character forward in the stream.
-- @return the character we just advanced over, or nil if we're at eof
function CharStream:advance()
  if self:eof() then return end

  local c = self:peek()
  self.Offset = self.Offset + 1
  -- We accept \r\n, \n\r, as well lone \n or \r. (In that case we'll return
  -- \n regardless of which came first, for consistency's sake.)
  if c == "\n" or c == "\r" then
    local c2 = self:peek()
    if (c2 == "\n" or c2 == "\r") and c ~= c2 then
      self.Offset = self.Offset + 1
    end
    self.Position.Line = self.Position.Line + 1
    self.Position.Col = 1
    return "\n"
  else
    self.Position.Col = self.Position.Col + 1
    return c
  end
end

--- Return a (not necessarily human-readable) representation of the current stream position.
function CharStream:pos()
  return {
    Offset = self.Offset,
    Position = { Line = self.Position.Line, Col = self.Position.Col }
  }
end

--- Set the position to a previously stored position.
function CharStream:backtrack(pos)
  self.Offset = assert(pos.Offset)
  self.Position.Line = assert(pos.Position.Line)
  self.Position.Col = assert(pos.Position.Col)
end

return CharStream

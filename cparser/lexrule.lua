--- Definition of 'lexical rules' - functions which, given a CharStream,
-- either consumes some input (ie. advances the stream) and succeeds (returns
-- true) or fails (returns false) having consumed no input.

local LexRule = { metatable = {} }

function LexRule.metatable.__call(t, ...) return t.__call(...) end

--- Given a function, wraps it into an object with convenient operators.
function LexRule.new(x)
  if type(x) == "function" then
    return setmetatable({ __call = x }, LexRule.metatable)
  elseif type(x) == "string" then
    return LexRule.string(x)
  else
    error("expected function or string, got " .. type(x))
  end
end
setmetatable(LexRule, { __call = function(LexRule, ...) return LexRule.new(...) end })

--- A LexRule that accepts any character.
-- TODO should this be a character class (ie. have __class)?
LexRule.any = LexRule(function(stream)
  if stream:eof() then return false else stream:advance() return true end
end)

--- Returns a LexRule that accepts any of the given characters.
-- Character ranges can be specified with eg. "A-Z".
function LexRule.class(...)
  local lookup = {}
  for i = 1, select('#', ...) do
    local range = select(i, ...)
    if type(range) == "table" then
      assert(range.__class, "non-class table as element of class")
      for k, v in pairs(range.__class) do
        if type(k) == "string" and type(v) == "boolean" then lookup[k] = v end
      end
    else
      assert(type(range) == "string", "expected string or class as argument to LexRule.class, got " .. type(range))
      if #range == 1 then
        lookup[range] = true
      elseif #range == 3 and string.sub(range, 2, 2) == "-" then
        local a, b = string.byte(range, 1), string.byte(range, 3)
        for c = a, b do
          lookup[string.char(c)] = true
        end
      else
        error("invalid string '" .. tostring(range) .. "' in character class")
      end
    end
  end

  local rule = LexRule(function(stream)
    if lookup[stream:peek()] then stream:advance() return true else return false end
  end)

  rule.__class = lookup
  return rule
end

function LexRule.string(str)
  if #str == 1 then
    return LexRule(function(stream)
      if stream:peek() == str then stream:advance() return true end
      return false
    end)
  elseif #str > 1 then
    return LexRule(function(stream)
      local pos = stream:pos()
      for i= 1, #str do
        if stream:peek() ~= string.sub(str, i, i) then
          stream:backtrack(pos)
          return false
        end
        stream:advance()
      end
      return true
    end)
  else
    error("empty LexRule.string")
  end
end

--- Return a LexRule that fails whenever self succeeds, and succeeds
-- (consuming no input) when self fails
function LexRule.metatable:__unm()
  -- TODO use self.__class when negating a character class
  return LexRule(function(stream)
    local pos = stream:pos()
    if self(stream) then
      stream:backtrack(pos)
      return false
    else
      return true
    end
  end)
end

--- Returns a LexRule that tries self, and if it succeeds also tries other.
function LexRule.metatable.__concat(left, right)
  return LexRule(function(stream)
    local pos = stream:pos()
    return left(stream) and (right(stream) or stream:backtrack(pos) and false)
  end)
end

--- Returns a LexRule that tries self, and if it fails then tries other.
function LexRule.metatable.__div(left, right)
  -- TODO use self.__class and other.__class when handling character classes
  return LexRule(function(stream)
    return left(stream) or right(stream)
  end)
end

--- Returns a LexRule that succeeds on left, as long as it couldn't succeed on right.
function LexRule.metatable.__sub(left, right)
  return (-right) .. left
end

--- Try rule repeatedly until it stops succeeding. Always return true.
function LexRule.many(rule)
  return LexRule(function(stream)
    while rule(stream) do end
    return true
  end)
end

--- Try rule, succeed regardless of whether rule succeeded.
function LexRule.optional(rule)
  return LexRule(function(stream)
    rule(stream)
    return true
  end)
end

function LexRule.metatable:__pow(bounds)
  local lower, upper
  if type(bounds) == "number" then
    lower, upper = bounds, bounds
  else
    assert(type(bounds) == "table")
    if #bounds == 1 then
      lower = assert(bounds[1], "missing bound for LexRule repetition")
      upper = lower
    elseif #bounds == 2 then
      lower = assert(bounds[1], "missing lower bound for LexRule repetition")
      upper = assert(bounds[2], "missing upper bound for LexRule repetition")
    else
      error("expected { number } or { number, number } for LexRule repetition")
    end
  end

  assert(lower >= 0, "negative number passed for LexRule repetition lower bound")
  assert(upper >= lower, "upper bound must be no less than lower bound for LexRule repetition")

  return LexRule.new(function(stream)
    local pos = stream:pos()
    for i = 1, lower do
      if not self(stream) then stream:backtrack(pos) return false end
    end
    for i = lower + 1, upper do
      if not self(stream) then break end
    end
    return true
  end)
end

return LexRule

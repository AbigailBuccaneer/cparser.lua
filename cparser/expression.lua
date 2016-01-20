local Expr = {}

function Expr.primaryExpression(parser)
  local data = parser:identifier() or parser:constant() or parser:stringLiteral() or Expr.genericSelection(parser)
  if data then return { Type = "primary-expression", data } end

  local pos = parser:pos()
  local openParen = parser:punctuator"("
  if not openParen then return nil end

  local expr = Expr.expression(parser)
  if not expr then parser:backtrack(pos) end

  local closeParen = parser:punctuator")"
  if not closeParen then parser:backtrack(pos) end

  return { Type = "primary-expression", openParen, expr, closeParen }
end

function Expr.genericSelection(parser)
  -- TODO
end

function Expr.expression(parser)
  -- TODO
end

return Expr

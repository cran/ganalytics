#' @include utils.R
#' @importFrom stringr str_replace_all str_match str_split_fixed str_split
#' @importFrom assertthat assert_that
#' @importFrom lazyeval as.lazy
#' @importFrom methods as setAs
NULL

# Coercing to .expr

# Need to consider escaping of the following characters in the operand:\|,;_
parseOperand <- function(operand, comparator) {
  if (isTRUE(comparator == "[]")) {
    operand <- str_split(operand, "\\|")[[1L]]
  } else if (isTRUE(comparator == "<>")) {
    operand <- str_split_fixed(operand, "_", 2L)[1L,]
  }
  operand <- gsub("\\\\", "\\", operand)
}

# Need to redo this to properly handle escaping with the \ used with GA.
setAs(from = "character", to = ".expr", def = function(from) {
  ops <- union(kGaOps$met, kGaOps$dim)
  ops <- str_replace_all(ops, "(\\[|\\])", "\\\\\\1")
  ops <- paste(ops, collapse = "|")
  comparator <- str_match(from, ops)[1L,1L]
  x <- str_split_fixed(from, ops, 2L)
  var <- Var(x[1L,1L])
  operand <- x[1L,2L]
  Expr(var, comparator, parseOperand(operand, comparator))
})

# Coercing from formula
setAs(from = "formula", to = ".expr", def = function(from) {
  lazy_expr <- as.lazy(from)
  assert_that(length(lazy_expr$expr) == 3L)
  comparator <- as.character(lazy_expr$expr[[1]])
  comparator <- switch(
    comparator,
    `%starts_with%` = "BEGINS_WITH",
    `%ends_with%` = "ENDS_WITH",
    `%contains%` = "=@",
    `%=@%` = "=@",
    `%matches%` = "=~",
    `%=~%` = "=~",
    `%in%` = "[]",
    `%[]%` = "[]",
    `%between%` = "<>",
    `%<>%` = "<>",
    comparator
  )
  var <- as.character(lazy_expr$expr[[2L]])
  operand <- as.expression(lazy_expr$expr[[3L]])
  Expr(var, comparator, eval(operand, envir = lazy_expr$env))
})

# Coercing to orExpr
setAs(from = ".expr", to = "orExpr", def = simpleCoerceToList)

setAs(from = "andExpr", to = "orExpr", def = function(from, to) {
  # This is currently only legal if the gaAnd object does not contain any gaOr
  # object of length greater than 1 OR if there is only one gaOr.

  # Check that all contained gaOr objects in the list have a length of 1
  assert_that(all(sapply(from, length) == 1L) | length(from) == 1L)

  # Otherwise, in a future implementation if any gaOr objects have a length greater
  # than 1, then they will need to be shortened to length 1 which is only possible
  # if each expression within that gaOr shares the same dimension and the
  # expression comparators and operands can be combined either as a match regex
  # or a match list.

  # Break apart the AND expression into OR expressions
  # then break apart each OR expression into single
  # expressions. Concatenate the single expressions
  # back up the chain. Then convert array into a list of
  # expressions to use for a new OR expression.

  orExpr <- as.list(do.call(c, do.call(c, from@.Data)))
  as(orExpr, to)
})

# Coercing to andExpr
setAs(from = "orExpr", to = "andExpr", def = simpleCoerceToList)

setAs(from = ".expr", to = "andExpr", def = function(from, to) {
  as(as(from, "orExpr"), "andExpr")
})

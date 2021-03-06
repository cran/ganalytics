% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Expr-generics.R, R/Expr-methods.R,
%   R/Segment-methods.R
\docType{methods}
\name{ScopeLevel}
\alias{ScopeLevel}
\alias{ScopeLevel<-}
\alias{ScopeLevel,gaSegMetExpr,missing-method}
\alias{ScopeLevel,gaSegMetExpr,character-method}
\alias{ScopeLevel<-,gaMetExpr,character-method}
\alias{ScopeLevel,.gaSegmentFilter,missing-method}
\alias{ScopeLevel,.gaSegmentFilter,character-method}
\alias{ScopeLevel<-,.gaSegmentFilter,character-method}
\alias{ScopeLevel<-,gaDynSegment,character-method}
\title{ScopeLevel}
\usage{
ScopeLevel(object, value)

ScopeLevel(object) <- value

\S4method{ScopeLevel}{gaSegMetExpr,missing}(object)

\S4method{ScopeLevel}{gaSegMetExpr,character}(object, value)

\S4method{ScopeLevel}{gaMetExpr,character}(object) <- value

\S4method{ScopeLevel}{.gaSegmentFilter,missing}(object)

\S4method{ScopeLevel}{.gaSegmentFilter,character}(object, value)

\S4method{ScopeLevel}{.gaSegmentFilter,character}(object) <- value

\S4method{ScopeLevel}{gaDynSegment,character}(object) <- value
}
\arguments{
\item{object}{A \code{.gaSegmentFilter} or \code{gaMetExpr} object.}

\item{value}{Optional new scope level to return an updated copy of the object
with the new scope applied. For \code{.gaSegmentFilters} this can be either
\code{'users'} or \code{'sessions'}. For metric expressions use either
\code{'perUser'}, \code{'perSession'}, \code{'perHit'} or
\code{'perProduct'}.}
}
\value{
The scope level as a character string, or returns a
\code{.gaSegmentFilter} or \code{gaMetExpr} object with the newly set
scope.
}
\description{
Get or set the scope level of a \code{.gaSegmentFilter} or \code{gaMetExpr}.

Set the scope level of a \code{.gaSegmentFilter} or a \code{gaMetExpr}.
}
\section{Methods (by class)}{
\itemize{
\item \code{object = gaSegMetExpr,value = missing}: Return the scope of the supplied metric used within a
segment definition.

\item \code{object = gaSegMetExpr,value = character}: Set the scope, as described by a character value, to
be applied to the supplied metric condition for use within a segment
expression.

\item \code{object = gaMetExpr,value = character}: Set the scope, as described by a character value, to
be applied to the supplied metric condition for use within a segment
expression.

\item \code{object = .gaSegmentFilter,value = missing}: Returns the scope of the supplied .gaSegmentFilter.

\item \code{object = .gaSegmentFilter,value = character}: Set the scope level of a .gaSegmentFilter to either
"user" or "session" level.

\item \code{object = .gaSegmentFilter,value = character}: Set the scope level of a .gaSegmentFilter to either
"user" or "session" level.

\item \code{object = gaDynSegment,value = character}: Set the scope level of a gaDynSegment to either
"user" or "session" level.
}}

\examples{
sessions_with_value <- Expr(~eventValue > 0, metricScope = "perSession")
ScopeLevel(sessions_with_value)
users_with_value_sessions <- Include(sessions_with_value)
ScopeLevel(users_with_value_sessions) <- "users"
sessions_with_value_segment <- ScopeLevel(users_with_value_sessions, "sessions")

}
\seealso{
Other dynamic segment functions: \code{\link{DynSegment}},
  \code{\link{Exclude}}, \code{\link{Include}},
  \code{\link{IsNegated}}, \code{\link{PerHit}},
  \code{\link{PerProduct}}, \code{\link{PerSession}},
  \code{\link{PerUser}},
  \code{\link{SegmentConditionFilter}},
  \code{\link{Segments}}, \code{\link{Segment}}

Other dynamic segment functions: \code{\link{DynSegment}},
  \code{\link{Exclude}}, \code{\link{Include}},
  \code{\link{IsNegated}}, \code{\link{PerHit}},
  \code{\link{PerProduct}}, \code{\link{PerSession}},
  \code{\link{PerUser}},
  \code{\link{SegmentConditionFilter}},
  \code{\link{Segments}}, \code{\link{Segment}}
}
\concept{dynamic segment functions}

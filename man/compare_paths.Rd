% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compare_paths.R
\name{compare_paths}
\alias{compare_paths}
\title{Compare simular paths}
\usage{
compare_paths(gps, same_paths, truth)
}
\arguments{
\item{gps}{sf sf pbect from gpx \code{gpx_to_point} with a path added from \code{add_paths}.}

\item{same_paths}{a table pof same paths produced with \code{find_same_paths}}

\item{truth}{set on known locations for each point in route}
}
\value{
a sf object with area, path lengths, and path times
}
\description{
Given a set of GPS points with defined paths, compares those with the same end nodes and compute the areal differnce between a direct line and the path choosen.
}

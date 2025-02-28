% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/version_control.R
\name{git_add}
\alias{git_add}
\title{Add Files to Git}
\usage{
git_add(paths, force = FALSE)
}
\arguments{
\item{paths}{Character vector of file paths to add}

\item{force}{Logical. Whether to force add ignored files. Default is FALSE.}
}
\value{
Invisibly returns TRUE if successful
}
\description{
Adds files to Git staging area.
}
\examples{
\dontrun{
git_add("README.md")
git_add(c("data/raw/iris.csv", "data/processed/features.csv"))
}
}

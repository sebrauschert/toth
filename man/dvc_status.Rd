% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/version_control.R
\name{dvc_status}
\alias{dvc_status}
\title{Check DVC Pipeline Status}
\usage{
dvc_status()
}
\value{
Character vector containing status output
}
\description{
Shows the status of the DVC pipeline, indicating which stages are up-to-date
and which need to be reproduced.
}
\examples{
\dontrun{
dvc_status()
}
}

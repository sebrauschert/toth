% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dvc_tracking.R
\name{write_csv_dvc}
\alias{write_csv_dvc}
\title{Write CSV with DVC tracking}
\usage{
write_csv_dvc(x, file, message = NULL, ...)
}
\arguments{
\item{x}{A data frame to write}

\item{file}{Path to write to}

\item{message}{Optional DVC commit message}

\item{...}{Additional arguments passed to readr::write_csv}
}
\value{
The input data frame (invisibly) to allow for further piping
}
\description{
A wrapper around readr::write_csv that automatically tracks the output file with DVC
}
\examples{
\dontrun{
data |> write_csv_dvc("data/processed/mydata.csv", "Updated data")
}
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dvc_tracking.R
\name{write_rds_dvc}
\alias{write_rds_dvc}
\title{Write RDS with DVC tracking}
\usage{
write_rds_dvc(
  object,
  file,
  message = NULL,
  stage_name = NULL,
  deps = NULL,
  metrics = FALSE,
  plots = FALSE,
  params = NULL,
  push = FALSE,
  ...
)
}
\arguments{
\item{object}{Object to save}

\item{file}{Path to write to}

\item{message}{Optional DVC commit message}

\item{stage_name}{Optional name for the DVC stage. If provided, creates a pipeline stage.}

\item{deps}{Character vector of dependency files (optional, for pipeline stages)}

\item{metrics}{Logical. Whether to mark the output as a DVC metric}

\item{plots}{Logical. Whether to mark the output as a DVC plot}

\item{params}{Named list of parameters for the stage (optional)}

\item{push}{Logical. Whether to push changes to Git remote (default: FALSE)}

\item{...}{Additional arguments passed to saveRDS}
}
\value{
The input object (invisibly) to allow for further piping
}
\description{
A wrapper around saveRDS that automatically tracks the output file with DVC
and optionally creates a DVC pipeline stage.
}
\examples{
\dontrun{
# Simple tracking
model |> write_rds_dvc(
  "models/model.rds",
  message = "Updated model",
  push = TRUE
)

# As part of a pipeline
model |> write_rds_dvc(
  "models/rf_model.rds",
  message = "Save trained random forest model",
  stage_name = "train_model",
  deps = c("data/processed/training.csv", "R/train_model.R"),
  params = list(ntree = 500),
  push = TRUE
)
}
}

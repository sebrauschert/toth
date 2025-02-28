#' Create a New Analytics Project
#'
#' Sets up a new analytics project with standardized structure and configuration
#' for reproducible analysis using DVC, Docker, renv, and Quarto.
#'
#' @param path Character. The path where the project should be created.
#' @param use_dvc Logical. Whether to initialize DVC. Default is TRUE.
#' @param use_docker Logical. Whether to set up Docker configuration. Default is TRUE.
#' @param use_renv Logical. Whether to initialize renv. Default is TRUE.
#' @param git_init Logical. Whether to initialize git repository. Default is TRUE.
#' @param open Logical. Whether to open the new project in RStudio. Default is TRUE.
#'
#' @return Invisibly returns the path to the created project.
#' @export
#'
#' @examples
#' \dontrun{
#' create_analytics_project("my_analysis")
#' }
create_analytics_project <- function(path,
                                   use_dvc = TRUE,
                                   use_docker = TRUE,
                                   use_renv = TRUE,
                                   git_init = TRUE,
                                   open = rlang::is_interactive()) {
  # Check if required system tools are available
  check_system_requirements(use_dvc, use_docker)
  
  # Normalize path
  path <- normalizePath(path, mustWork = FALSE)
  
  # Create the basic project using usethis
  usethis::create_project(
    path = path,
    rstudio = TRUE,  # Always create as RStudio project
    open = FALSE     # We'll handle opening later
  )
  
  # Change to project directory for remaining setup
  old_wd <- setwd(path)
  on.exit({
    setwd(old_wd)
    # Ensure the project is set back to the new project at the end
    usethis::proj_set(path)
  })

  # Create standard directory structure
  dirs <- c(
    "data/raw",
    "data/processed",
    "R",
    "reports",
    "docker"
  )
  
  lapply(dirs, dir.create, recursive = TRUE, showWarnings = FALSE)

  # Initialize Git if requested (before DVC to ensure .dvc is tracked)
  if (git_init) {
    # Initialize git repository
    git_init_repo()
    
    # Create initial .gitignore before any other files
    write_gitignore()
    
    # Initial commit of just the .gitignore
    git_add(".gitignore")
    git_commit("Initial commit with .gitignore")
  }

  # Initialize DVC if requested (after git setup but before adding data directories)
  if (use_dvc) {
    system2("dvc", args = c("init"))
    if (git_init) {
      # Add .dvc directory to git
      git_add(".dvc")
      git_commit("Initialize DVC")
    }
    setup_dvc_tracking()
  } else {
    # If not using DVC, create .gitkeep files and track them
    file.create("data/raw/.gitkeep")
    file.create("data/processed/.gitkeep")
    if (git_init) {
      git_add(c("data/raw/.gitkeep", "data/processed/.gitkeep"))
      git_commit("Add .gitkeep files to data directories")
    }
  }

  # Set up Docker if requested
  if (use_docker) {
    setup_docker()
    if (git_init) {
      git_add("docker")
      git_commit("Add Docker configuration")
    }
  }
  
  # Initialize renv if requested
  if (use_renv) {
    renv::init()
    
    # Install thoth in the new project
    cli::cli_alert_info("Installing thoth package in the project environment...")
    
    # Create a script to install thoth in the project environment
    setup_script <- file.path(path, "setup_thoth.R")
    writeLines(c(
      "# Setup script for installing thoth",
      "renv::init()",
      "renv::install('sebrauschert/thoth')",
      "renv::snapshot()"
    ), setup_script)
    
    # Run the installation script in a new R session
    system2("Rscript", args = c(setup_script))
    unlink(setup_script)
    
    if (git_init) {
      git_add(c("renv.lock", "renv"))
      git_commit("Initialize renv and install dependencies")
    }
  }

  # Create README
  write_readme(path)
  if (git_init) {
    git_add("README.md")
    git_commit("Add README")
  }

  # Set up Quarto template
  setup_quarto_template()
  if (git_init) {
    git_add("reports")
    git_commit("Add Quarto template")
  }

  # Success message
  cli::cli_alert_success("Analytics project successfully created at {.path {path}}")
  
  # Open the project if requested
  if (open) {
    if (rstudioapi::isAvailable()) {
      # First, ensure all R project files are tracked
      if (git_init) {
        # Add all R project files
        git_add(c(
          "*.Rproj",
          ".Rprofile",
          "renv",
          ".Rproj.user"
        ), force = TRUE)
        git_commit("Add R project files")
      }
      
      # Find the .Rproj file
      rproj_file <- list.files(path, pattern = "\\.Rproj$", full.names = TRUE)
      if (length(rproj_file) == 1) {
        # Open the project in a new session
        tryCatch({
          rstudioapi::openProject(rproj_file, newSession = TRUE)
          cli::cli_alert_success("Opened new project in RStudio")
        }, error = function(e) {
          cli::cli_alert_warning("Failed to open project in RStudio: {e$message}")
          cli::cli_alert_info("You can manually open the project at: {.path {rproj_file}}")
        })
      } else {
        cli::cli_alert_warning("Could not find .Rproj file in {.path {path}}")
      }
    } else {
      cli::cli_alert_warning("RStudio API not available. Setting working directory instead.")
      setwd(path)
      cli::cli_alert_info("Working directory changed to: {.path {path}}")
    }
  }
  
  invisible(path)
}

#' Check System Requirements
#'
#' @param use_dvc Logical. Whether DVC is required
#' @param use_docker Logical. Whether Docker is required
#' @keywords internal
check_system_requirements <- function(use_dvc, use_docker) {
  if (use_dvc) {
    if (!check_command("dvc")) {
      cli::cli_abort("DVC is not installed. Please install it first: https://dvc.org/doc/install")
    }
  }
  
  if (use_docker) {
    if (!check_command("docker")) {
      cli::cli_abort("Docker is not installed. Please install it first: https://docs.docker.com/get-docker/")
    }
  }
}

#' Write Default .gitignore File
#' @keywords internal
write_gitignore <- function() {
  gitignore_content <- c(
    # R specific ignores
    ".Rproj.user/",
    ".Rhistory",
    ".RData",
    ".Ruserdata",
    "*.Rproj",
    # Data directories - exclude everything by default
    "/data/raw/*",
    "/data/processed/*",
    # But allow .gitkeep files if needed
    "!/data/raw/.gitkeep",
    "!/data/processed/.gitkeep",
    # R environment
    ".env",
    "renv/library/",
    "renv/python/",
    "renv/staging/",
    # DVC specific - don't ignore these
    "!.dvc/config",
    "!.dvc/cache",
    "!*.dvc"
  )
  writeLines(gitignore_content, ".gitignore")
}

#' Set up DVC Tracking
#' @keywords internal
setup_dvc_tracking <- function() {
  # Create .dvcignore
  dvcignore_content <- c(
    "# Add patterns of files dvc should ignore, which are specific to your project",
    "# For example: *.png, *.log",
    "",
    # Ignore R-specific files that shouldn't be tracked by DVC
    ".Rproj.user/",
    ".Rhistory",
    ".RData",
    ".Ruserdata",
    "*.Rproj",
    "renv/",
    ".env"
  )
  writeLines(dvcignore_content, ".dvcignore")
  
  # Create .gitkeep files
  file.create("data/raw/.gitkeep")
  file.create("data/processed/.gitkeep")
  
  if (file.exists(".git")) {
    # Add .gitkeep files to git
    git_add(c("data/raw/.gitkeep", "data/processed/.gitkeep"))
    git_commit("Add .gitkeep files to data directories")
    
    # Add .dvcignore to git
    git_add(".dvcignore")
    git_commit("Add .dvcignore file")
  }
}

#' Set up Docker Configuration
#' @keywords internal
setup_docker <- function() {
  # Get current R version
  r_version <- paste0(R.version$major, ".", R.version$minor)
  
  dockerfile_content <- c(
    sprintf("FROM rocker/rstudio:%s", r_version),
    "",
    "# Install system dependencies",
    "RUN apt-get update && apt-get install -y \\",
    "    python3-pip \\",
    "    && rm -rf /var/lib/apt/lists/*",
    "",
    "# Install DVC",
    "RUN pip3 install dvc",
    "",
    "# Create working directory",
    "WORKDIR /project",
    "",
    "# Copy project files",
    "COPY . /project/",
    "",
    "# Install R packages",
    "RUN R -e 'install.packages(\"renv\")'",
    "RUN R -e 'renv::restore()'",
    "",
    "# Set permissions for RStudio user",
    "RUN chown -R rstudio:rstudio /project",
    "",
    "# Command to keep the container running",
    "CMD [\"/init\"]"
  )
  writeLines(dockerfile_content, "docker/Dockerfile")
  
  # Create docker-compose.yml
  docker_compose_content <- c(
    "services:",
    "  rstudio:",
    "    build: .",
    "    ports:",
    "      - \"8787:8787\"",
    "    environment:",
    "      - PASSWORD=rstudio",
    "      - ROOT=TRUE",
    "    volumes:",
    "      - .:/project",
    "    user: rstudio"
  )
  writeLines(docker_compose_content, "docker/docker-compose.yml")
  
  cli::cli_alert_success("Docker configuration created with R version {r_version}")
}

#' Write Project README
#' @keywords internal
write_readme <- function(project_name) {
  readme_content <- c(
    paste0("# ", basename(project_name)),
    "",
    "## Project Overview",
    "",
    "Describe your project here.",
    "",
    "## Project Structure",
    "",
    "```",
    "+-- data/           # Data files",
    "|   +-- raw/       # Raw data, tracked by DVC",
    "|   +-- processed/ # Processed data, tracked by DVC",
    "+-- R/             # R scripts",
    "+-- reports/       # Analysis reports (Quarto)",
    "+-- docker/        # Docker configuration",
    "```",
    "",
    "## Setup",
    "",
    "1. Clone this repository",
    "2. Install dependencies: `renv::restore()`",
    "3. Pull data: `dvc pull`",
    "",
    "## Usage",
    "",
    "Describe how to use the project here."
  )
  writeLines(readme_content, "README.md")
}

#' Set up Quarto Template
#' @keywords internal
setup_quarto_template <- function() {
  # Create reports directory if it doesn't exist
  dir.create("reports", showWarnings = FALSE)
  
  # Create a basic Quarto template
  quarto_template <- c(
    "---",
    "title: \"Analysis Report\"",
    "author: \"Your Name\"",
    "date: \"`r Sys.Date()`\"",
    "format:",
    "  html:",
    "    theme: cosmo",
    "    toc: true",
    "    code-fold: true",
    "---",
    "",
    "```{r setup, include=FALSE}",
    "knitr::opts_chunk$set(",
    "  echo = TRUE,",
    "  message = FALSE,",
    "  warning = FALSE",
    ")",
    "```",
    "",
    "## Overview",
    "",
    "## Data Import and Processing",
    "",
    "## Analysis",
    "",
    "## Results",
    "",
    "## Conclusions"
  )
  writeLines(quarto_template, "reports/template.qmd")
} 
#' Add useful infrastructure to a package.
#'
#'
#' @param pkg package description, can be path or package name. See
#'   \code{\link{as.package}} for more information.
#' @name infrastructure
#' @aliases add_test_infrastructure
#' @aliases add_rstudio_project
NULL

#' @section \code{use_testthat}:
#' Add testing infrastructure to a package that does not already have it.
#' This will create \file{tests/testthat.R}, \file{tests/testthat/} and
#' add \pkg{testthat} to the suggested packages. This is called
#' automatically from \code{\link{test}} if needed.
#' @rdname infrastructure
#' @export
use_testthat <- function(pkg = ".") {
  pkg <- as.package(pkg)

  check_testthat()
  if (uses_testthat(pkg)) {
    stop("Package already has testing infrastructure", call. = FALSE)
  }

  # Create tests/testthat and install file for R CMD CHECK
  dir.create(file.path(pkg$path, "tests", "testthat"),
    showWarnings = FALSE, recursive = TRUE)
  writeLines(render_template("testthat.R", list(name = pkg$package)),
    file.path(pkg$path, "tests", "testthat.R"))

  add_desc_package(pkg, "Suggests", "testthat")

  invisible(TRUE)
}

#' @export
add_test_infrastructure <- use_testthat

#' @section \code{use_rstudio}:
#' Does not modify \code{.Rbuildignore} as RStudio will do that when
#' opened for the first time.
#' @export
#' @rdname infrastructure
use_rstudio <- function(pkg = ".") {
  pkg <- as.package(pkg)

  path <- file.path(pkg$path, paste0(pkg$package, ".Rproj"))
  if (file.exists(path)) {
    stop(pkg$package, ".Rproj already exists", call. = FALSE)
  }
  message("Adding RStudio project file to ", pkg$package)

  template_path <- system.file("templates/template.Rproj", package = "devtools")
  file.copy(template_path, path)

  add_build_ignore(pkg, ".travis.yml")

  invisible(TRUE)
}

#' @export
#' @rdname infrastructure
add_rstudio_project <- use_rstudio


#' @section \code{use_knitr}:
#' Creates \code{vignettes/} and adds needed packages to \code{DESCRIPTION}.
#' @export
#' @rdname infrastructure
use_knitr <- function(pkg = ".") {
  pkg <- as.package(pkg)

  add_desc_package(pkg, "Suggests", "knitr")
  add_desc_package(pkg, "VignetteBuilder", "knitr")
  dir.create(file.path(pkg$path, "vignettes"), showWarnings = FALSE)

  message(
    "Put .Rmd in vignettes/. Each must include:\n",
    "<!-- \n",
    "%\\VignetteEngine{knitr::knitr}\n",
    "%\\VignetteIndexEntry{Vignette title}\n",
    "-->\n"
  )
}

#' @section \code{use_rcpp}:
#' Creates \code{src/} and adds needed packages to \code{DESCRIPTION}.
#' @export
#' @rdname infrastructure
use_rcpp <- function(pkg = ".") {
  pkg <- as.package(pkg)

  add_desc_package(pkg, "LinkingTo", "Rcpp")
  add_desc_package(pkg, "Imports", "Rcpp")
  dir.create(file.path(pkg$path, "src"), showWarnings = FALSE)

  message(
    "Include the following roxygen tags somewhere in your package:\n",
    "#' @useDynLib mypackage\n",
    "#' @importFrom Rcpp sourceCpp"
  )
}

#' @rdname infrastructure
#' @section \code{use_travis}:
#' Add basic travis template to a package. Also adds \code{.travis.yml} to
#' \code{.Rbuildignore} so it isn't included in the built package.
#' @export
use_travis <- function(pkg = ".") {
  pkg <- as.package(pkg)

  path <- file.path(pkg$path, ".travis.yml")
  if (file.exists(path)) {
    stop(".travis.yml already exists", call. = FALSE)
  }
  message("Adding .travis.yml to ", pkg$package, ". Next: \n",
    " * Turn on travis for this repo at https://travis-ci.org/profile\n",
    " * Add a travis shield to your README.md"
  )

  template_path <- system.file("templates/travis.yml", package = "devtools")
  file.copy(template_path, path)

  add_build_ignore(pkg, ".travis.yml")

  invisible(TRUE)
}

#' @rdname infrastructure
#' @export
add_travis <- use_travis


add_desc_package <- function(pkg = ".", field, name) {
  pkg <- as.package(pkg)
  desc_path <- file.path(pkg$path, "DESCRIPTION")

  desc <- read_dcf(desc_path)
  old <- desc[[field]]
  if (is.null(old)) {
    new <- name
    changed <- TRUE
  } else {
    if (!grepl(name, old)) {
      new <- paste0(old, ",\n    ", name)
      changed <- TRUE
    } else {
      changed <- FALSE
    }
  }
  if (changed) {
    desc[[field]] <- new
    write_dcf(desc_path, desc)
  }
  invisible(changed)
}

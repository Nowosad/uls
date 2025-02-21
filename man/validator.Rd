% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/validator.R
\name{validator}
\alias{validator}
\title{Validates Data}
\usage{
validator(
  x,
  site_code = NULL,
  start_date = as.Date(-Inf, origin = "1970-01-01"),
  end_date = as.Date(Inf, origin = "1970-01-01"),
  validation_table,
  validation_table_ext
)
}
\arguments{
\item{x}{Path to a \code{.dat} file}

\item{site_code}{Code of the site, either \code{"KU"}, \code{"BR"}, \code{"RZ"}}

\item{start_date}{The start date of the validation period}

\item{end_date}{The end state of the validation period}

\item{validation_table}{Additional argument: A path to a .xlsx file
with a basic validation table.
By default, a built-in table is used.}

\item{validation_table_ext}{Additional argument: A path to a .xlsx file
with an extended validation table.
By default, a built-in table is used.}
}
\value{
A data frame with possible errors
}
\description{
Validates Data
}
\examples{
dat_filepath = system.file("dat/CR3000_Rain.dat", package = "puls")
validator(dat_filepath, site_code = "BR",
    start_date = as.Date("2017-07-25"), end_date = as.Date("2020-07-30"))

}

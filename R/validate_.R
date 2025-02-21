#' Validate Several Separate Border Cases
#'
#' This function is used iternally in the `validator()` function.
#'
#' @param y A list with two data frames - `correct_df` and `error_df`
#' @param param_df A data frame with basic parameters' ranges
#' @param howmanysd Specifies how many standard deviations from the provided mean are accepted
#'
#' @return A list with two data frames - `correct_df` and `error_df`.
#'     `correct_df` stores data without any detected problems and
#'     `error_df` stores data with detected problems together with
#'     a specified problem description.
#'
#' @rdname validate_
#' @export
#'
#' @examples

validate_nan = function(y){
  correct_df = y[["correct_df"]]
  error_df = y[["error_df"]]

  new_error_df = correct_df[is.nan(correct_df$value), c("TIMESTAMP", "RECORD", "name", "value")]
  new_error_df$problem = "NaN values"

  error_df = rbind(error_df, new_error_df)
  correct_df = correct_df[!is.nan(correct_df$value), ]

  list(correct_df = correct_df,
       error_df = error_df)
}

#' @name validate_
#' @export
validate_min = function(y, param_df){
  if (!is.na(param_df$min_value)){
    correct_df = y[["correct_df"]]
    error_df = y[["error_df"]]

    new_error_df = correct_df[correct_df$value < param_df$min_value, c("TIMESTAMP", "RECORD", "name", "value")]
    new_error_df$problem = paste("Values below the expected minimum of",
                                 param_df$min_value)

    error_df = rbind(error_df, new_error_df)
    correct_df = correct_df[correct_df$value >= param_df$min_value, ]

    list(correct_df = correct_df,
         error_df = error_df)
  } else {
    y
  }
}

#' @name validate_
#' @export
validate_max = function(y, param_df){
  if (!is.na(param_df$max_value)){
    correct_df = y[["correct_df"]]
    error_df = y[["error_df"]]

    new_error_df = correct_df[correct_df$value > param_df$max_value, c("TIMESTAMP", "RECORD", "name", "value")]
    new_error_df$problem = paste("Values above the expected maximum of",
                                 param_df$max_value)

    error_df = rbind(error_df, new_error_df)
    correct_df = correct_df[correct_df$value <= param_df$max_value, ]

    list(correct_df = correct_df,
         error_df = error_df)
  } else {
    y
  }
}

#' @name validate_
#' @export
validate_longterm = function(y, param_df_ext, howmanysd = 3){
  if (nrow(param_df_ext) > 0){

    correct_df = y[["correct_df"]]
    error_df = y[["error_df"]]

    correct_df = correct_df %>%
      dplyr::mutate(DOY = lubridate::yday(TIMESTAMP),
                                       HOUR = lubridate::hour(TIMESTAMP),
                                       MIN = lubridate::minute(TIMESTAMP)) %>%
      dplyr::left_join(param_df_ext, by = c("parameter", "DOY", "HOUR", "MIN"))

    longterm_sds = howmanysd * correct_df$SD
    longterm_range_min = correct_df$AVG -longterm_sds
    longterm_range_max = correct_df$AVG + longterm_sds

    problems = correct_df$value < longterm_range_min | correct_df$value > longterm_range_max
    problems[is.na(problems)] = FALSE
    longterm_range_min = longterm_range_min[problems]
    longterm_range_max = longterm_range_max[problems]

    new_error_df = correct_df[problems,
                              c("TIMESTAMP", "RECORD", "name", "value")]
    new_error_df$problem = paste("Values outside of the long-term range between",
                                 longterm_range_min, " and", longterm_range_max)


    error_df = rbind(error_df, new_error_df)
    correct_df = correct_df[!problems,
                            c("TIMESTAMP", "RECORD", "name", "value", "parameter", "site")]

    list(correct_df = correct_df,
         error_df = error_df)
  } else{
    y
  }
}


#' @name validate_
#' @export
validate_delta = function(y, param_df_ext, howmany = 3){
  if (nrow(param_df_ext) > 0){

    correct_df = y[["correct_df"]]
    error_df = y[["error_df"]]

    correct_df = correct_df %>%
      dplyr::mutate(DOY = lubridate::yday(TIMESTAMP),
             HOUR = lubridate::hour(TIMESTAMP),
             MIN = lubridate::minute(TIMESTAMP)) %>%
      dplyr::left_join(param_df_ext, by = c("parameter", "DOY", "HOUR", "MIN"))

    longterm_deltas = howmany * correct_df$DELTA
    # longterm_range_min = correct_df$AVG - longterm_deltas
    # longterm_range_max = correct_df$AVG + longterm_deltas

    correct_df = correct_df %>%
      dplyr::mutate(delta_value = dplyr::lag(value - dplyr::lag(value)))

    problems = correct_df$delta_value > longterm_deltas
    problems[is.na(problems)] = FALSE
    longterm_deltas = longterm_deltas[problems]

    new_error_df = correct_df[problems,
                              c("TIMESTAMP", "RECORD", "name", "value")]
    new_error_df$problem = paste("Delta issue: change of ",
                                 correct_df[problems, "delta_value", drop = TRUE],
                                 " instead of below",
                                 longterm_deltas)

    error_df = rbind(error_df, new_error_df)
    correct_df = correct_df[!problems,
                            c("TIMESTAMP", "RECORD", "name", "value", "parameter", "site")]

    list(correct_df = correct_df,
         error_df = error_df)
  } else{
    y
  }
}


validate_longterm_old = function(y, param_df, howmanysd = 3){
  if (!is.na(param_df$longterm_sd)){
    longterm_sds = howmanysd * param_df$longterm_sd
    longterm_range = param_df$longterm_avg + c(-longterm_sds, longterm_sds)

    correct_df = y[["correct_df"]]
    error_df = y[["error_df"]]

    new_error_df = correct_df[!dplyr::between(correct_df$value, longterm_range[1], longterm_range[2]), c("TIMESTAMP", "RECORD", "name", "value")]
    new_error_df$problem = "Values outside of the long-term range"

    error_df = rbind(error_df, new_error_df)
    correct_df = correct_df[dplyr::between(correct_df$value, longterm_range[1], longterm_range[2]), ]

    list(correct_df = correct_df,
         error_df = error_df)
  } else {
    y
  }
}

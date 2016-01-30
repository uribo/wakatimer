# UTILITIES
# - msg_ver()
# - recent_files()
# - check_file_active()
# - get_rproj_name()
# - get_hbranch_name()
# - record_files()

#' Platform versioning
#' @name msg_ver
msg_ver <- function() {
  message(paste0(
    "The wakatimer begin to record your code as heartbeats!\n ",
    if (.Platform$OS.type == "unix") {
      paste0(
        remoji::emoji("computer"),
        utils::sessionInfo()$R.version$language,
        " (",
        utils::sessionInfo()$R.version$major,
        ".",
        utils::sessionInfo()$R.version$minor,
        ") ",
        ifelse(
          .Platform$GUI == "RStudio",
          paste0(
            remoji::emoji("large_blue_circle"),
            devtools::session_info()$platform$ui,
            " "
          ),
          " "
        ),
        remoji::emoji("package"),
        "wakatimer (",
        utils::packageVersion("wakatimer"),
        ")"
      )
    } else {
      paste0(
        utils::sessionInfo()$R.version$language,
        " (",
        utils::sessionInfo()$R.version$major,
        ".",
        utils::sessionInfo()$R.version$minor,
        ") ",
        devtools::session_info()$platform$ui,
        "wakatimer (",
        utils::packageVersion("wakatimer"),
        ")"
      )
    }
  ))
}

#' Get recently opened file name
#' @param n integer. retern file numbers. default is 15 .(max)
#' @return data frame. recent open files in RStudio session. Newer to older
#' @import dplyr
#' @name recent_files
#' @export
recent_files <- function(n = 15) {
  if (is.null(.wakatimerEnv$df.files))
    .wakatimerEnv$df.files <- dplyr::data_frame()
  if (n > 15) {
    warning("over request. display only 15 files.", call. = FALSE)
    n <- 15
  }
  .wakatimerEnv$df.files <-
    ifelse(
      .Platform$OS.type == "windows",
      paste0(
        Sys.getenv("HOMEPATH"),
        "\\AppData\\Local\\RStudio-Desktop\\monitored\\lists\\file_mru"
      ),
      paste0(
        Sys.getenv("HOME"),
        "/.rstudio-desktop/monitored/lists/file_mru"
      )
    ) %>%
    readLines() %>%
    .[1:n] %>%
    file.info(., extra_cols = FALSE) %>%
    dplyr::add_rownames("file") %>%
    dplyr::select(file, size, mtime) %>%
    dplyr::filter(!is.na(size)) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(lines = length(readLines(file))) %>%
    dplyr::ungroup()

    return(.wakatimerEnv$df.files)
}

#' Getting Rproject name
#' @return Active RProject name
#' @name get_rproj_name
#' @export
get_rproj_name <- function() {
  if (is.null(rstudioapi::getActiveProject())) {
    NULL
  } else {
    gsub(".+/", "", rstudioapi::getActiveProject())
  }
  # alternative

}

#' Get git head branch name
#' @return current git (HAED) branch  name
#' @import git2r
#' @importFrom  purrr map_lgl
#' @name get_hbranch_name
#' @export
get_hbranch_name <- function() {
  if (is.null(rstudioapi::getActiveProject())) {
    NULL
  }
  if (!file.exists(paste0(getwd(), "/.git"))) {
    NULL
  } else {
    # exist git repository
    repo_branches <-
      git2r::repository(rstudioapi::getActiveProject()) %>%
      git2r::branches(flags = "local")
    head_branch <-
      repo_branches %>%
      purrr::map_lgl(git2r::is_head) %>%
      which(. == 1) %>%
      as.numeric()
    repo_branches[[head_branch]]@name
  }
}

#' Record file status to environment
#' @param df data frame
#' @name record_files
#' @export
record_files <- function(df = NULL) {
  if (is.null(.wakatimerEnv$df.files))
    recent_files()

  .wakatimerEnv$df.files %>%
    dplyr::rename(entity = file) %>%
    dplyr::filter(grepl(
      paste0(rstudioapi::getActiveProject(), "/.+"),
      path.expand(entity)
    )) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(time = as.numeric(mtime)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-size, -mtime) %>%
    return(.)
}

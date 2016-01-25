# UTILITIES
# - file_info()

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
  # Windows: C:\Users\201_User\AppData\Local\RStudio-Desktop\monitored\lists\file_mru
  # Windows: HOMEPATH -> \Users\201_User
  .wakatimerEnv$df.files <- paste0(Sys.getenv("HOME"),
         "/.rstudio-desktop/monitored/lists/file_mru") %>%
    readLines() %>%
    .[1:n] %>%
    file.info(., extra_cols = FALSE) %>%
    dplyr::add_rownames("file") %>%
    dplyr::select(file, size, mtime) %>%
    dplyr::filter(!is.na(size)) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(lines = length(readLines(file)))

    return(.wakatimerEnv$df.files)
}


#' Check open file condition
#' @importFrom rstudioapi getActiveDocumentContext
#' @name check_file_active
check_file_active <- function() {
  if (!rstudioapi::getActiveDocumentContext()$path %in% .wakatimerEnv$df.files$file) {
    .wakatimerEnv$df.files <- recent_files()
    if (rstudioapi::getActiveDocumentContext()$path %in% .wakatimerEnv$df.files$file) {
      rstudioapi::getActiveDocumentContext()$path
    } else {
      message("This file is save yet!")
    }
  } else {
    rstudioapi::getActiveDocumentContext()$path
  }
}

#' Getting Rproject name
#' @return Active RProject name
#' @name get_rproj_name
get_rproj_name <- function() {
  if (is.null(rstudioapi::getActiveProject())) {
    NULL
  } else {
    gsub(".+/", "", rstudioapi::getActiveProject())
  }
  # alternative

}

.get_rproj_name <- function() {



    dplyr::mutate(rproj = ifelse(identical(character(0), grep("^.*\\.Rproj$", file %>% dirname() %>% list.files(), value = TRUE)),
                                 grep("^.*\\.Rproj$", file %>% dirname() %>% list.files(), value = TRUE),
                                 NA)) %>%
    dplyr::ungroup()
  if (identical(character(0), grep("^.*\\.Rproj$", list.files(dirname(.wakatimerEnv$df.files$file[1])), value = TRUE)) == TRUE) {
    NULL
  } else {

  }
}

#' Get git head branch name
#' @return current git (HAED) branch  name
#' @import git2r
#' @importFrom  purrr map_lgl
#' @name get_hbranch_name
get_hbranch_name <- function() {
  if (file.exists("./.git") == FALSE) {
    NULL
  } else {
    # exist git repository
    repo_branches <-
      git2r::repository(rstudioapi::getActiveProject()) %>%
      git2r::branches(flags = "local")
    head_branch <-
      repo_branches %>%
      purrr::map_lgl(git2r::is_head) %>%
      which(. == TRUE) %>%
      as.numeric()
    repo_branches[[head_branch]]@name
  }
}

#' Making posting data
#' @import dplyr
#' @name file_info
#' @export
file_info <- function() {
  active.file <- check_file_active()
  # FLAG:
  if (is.null(active.file))
    warning("This function is abailable on saved source file.", call. = FALSE)

  # FLAG: file modified?
  if (as.numeric(file.info(active.file, extra_cols = FALSE)$mtime) >
      .wakatimerEnv$df.files %>%
      dplyr::filter(file %in% active.file) %>% .$mtime %>% as.numeric()) {
    flag2save <- TRUE
  } else {
    flag2save <- FALSE
  }

  edit.file.info <- list(
    entity = active.file,
    type = "file",
    time = as.numeric(file.info(active.file, extra_cols = FALSE)$mtime),
    lines = length(readLines(active.file)),
    lineno = NULL,
    cursorpos = NULL,
    project = NULL,
    branch = NULL,
    language =  gsub(".+\\.", "", active.file),
    is_debugging = FALSE,
    is_write = flag2save
  )

  # FLAG: exit in project dir?
  if (path.expand(active.file) %in% list.files(rstudioapi::getActiveProject(),
                                               full.names = TRUE,
                                               recursive = TRUE)) {
    edit.file.info$project = get_rproj_name()
    edit.file.info$branch  = get_hbranch_name()
  }

  # FLAG: Identical edit file and active file
  if (identical(active.file,
                rstudioapi::getActiveDocumentContext()$path)) {
    edit.file.info$lineno = as.numeric(getActiveDocumentContext()$selection[[1]]$range$start["row"])
    edit.file.info$cursorpos = as.numeric(getActiveDocumentContext()$selection[[1]]$range$start["column"])
  }
  return(edit.file.info)
}

#' Record file status to environment
#' @param df data frame
#' @name record_files
record_files <- function(df = NULL) {
  if (is.null(.wakatimerEnv$df.files))
    recent_files()
  df %>%
    dplyr::rename(entity = file) %>%
    dplyr::filter(grepl(
      paste0(rstudioapi::getActiveProject(), "/.+"),
      path.expand(entity)
    )) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      time = as.numeric(mtime)) %>%
    dplyr::select(-size, -mtime) %>%
    return(.)
}

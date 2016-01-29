#' Sync file modify data to local database
#' @param local logical.
#' @import dplyr
#' @importFrom DBI dbWriteTable
#' @name wt_sync
wt_sync <- function(local = FALSE) {
  db_con <-
    dplyr::src_sqlite(paste(path.package("wakatimer"), ".wakatime.db", sep = "/"), create = FALSE)

  df.files.load <- db_con %>%
    dplyr::tbl(ifelse(is.null(get_rproj_name()), "heartbeats_1", get_rproj_name())) %>%
    as.data.frame() %>%
    dplyr::rename(entity = file) %>%
    dplyr::filter(grepl(
      paste0(rstudioapi::getActiveProject(), "/.+"),
      path.expand(entity)
    )) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(time = as.numeric(atime)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-size, -atime)

  df.files.quit <-
    recent_files() %>% record_files() %>%
    dplyr::bind_rows(df.files.load) %>%
    dplyr::distinct(time)

  exist.files <-
    df.files.quit %>% dplyr::filter(is_write == 0) %>% .$entity

  df.sync <- df.files.quit %>%
    dplyr::filter(entity %in% exist.files)

  if (nrow(df.sync) >= 1) {
    df.sync %<>% dplyr::arrange(time, entity) %>%
      dplyr::mutate(
        type = "file",
        lineno = NULL,
        cursorpos = NULL,
        project = ifelse(is.null(get_rproj_name()), "", get_rproj_name()),
        branch = ifelse(is.null(get_hbranch_name()), "", get_hbranch_name()),
        language = gsub(".+\\.", "", entity),
        is_debugging = FALSE,
        is_write = ifelse(is.na(is_write), TRUE, FALSE)
      )
    if (local == TRUE)
      DBI::dbWriteTable(
        db_con$con,
        "tmp",
        df.sync %>% as.data.frame(),
        append = TRUE,
        overwrite = FALSE
      )
    return(df.sync)
  }
}

#' Sync file modify data as heartbeats
#' @param local logical.
#' @importFrom jsonlite toJSON
#' @importFrom rlist list.load
#' @importFrom httr POST
#' @importFrom httr add_headers
#' @importFrom pforeach npforeach
#' @name wt_post
wt_post <- function(local = FALSE) {
  if (local == TRUE) {
    json.sync <-
      dplyr::src_sqlite(paste(path.package("wakatimer"), ".wakatime.db", sep = "/"), create = FALSE) %>%
      dplyr::tbl("tmp") %>%
      dplyr::collect() %>%
      dplyr::arrange(time, entity) %>%
      dplyr::mutate(
        type = "file",
        lineno = NULL,
        cursorpos = NULL,
        project = ifelse(is.null(get_rproj_name()), "", get_rproj_name()),
        branch = ifelse(is.null(get_hbranch_name()), "", get_hbranch_name()),
        language = gsub(".+\\.", "", entity),
        is_debugging = FALSE,
        is_write = ifelse(is.na(is_write), TRUE, FALSE)
      ) %>%
      jsonlite::toJSON(pretty = FALSE) %>%
      rlist::list.load()
  } else if (local == FALSE) {
    json.sync <- wt_sync(local = FALSE) %>%
      jsonlite::toJSON(pretty = FALSE) %>%
      rlist::list.load()
  }

  if (is.list(json.sync) & length(json.sync) >= 1) {
    pforeach::npforeach(i = 1:length(json.sync))({
      httr::POST(
        "https://api.wakatime.com/",
        path = "api/v1/heartbeats",
        config = httr::add_headers(
          `User-Agent` = paste0(
            sessionInfo()$R.version$language,
            "/",
            sessionInfo()$R.version$major,
            ".",
            sessionInfo()$R.version$minor,
            " RStudio-",
            rstudioapi::versionInfo()$mode,
            "/",
            rstudioapi::getVersion(),
            " wakatimer/",
            packageVersion("wakatimer")
          ),
          `connection` = "keep-alive",
          `accept-encoding` = "gzip,deflate",
          `Authorization` = paste(
            "Bearer",
            gen_token() %>% .$credentials %>% .$access_token
          ),
          `Content-Type`  = "application/json"
        ),
        body = json.sync[[i]],
        encode = "json"
      )
    })
  }
}

#' Sync modificate files between sesion
#' @import dplyr
#' @importFrom jsonlite toJSON
#' @importFrom rlist list.load
#' @name wt_sync_session
wt_sync_session <- function() {
  .wakatimerEnv$db_con <-
    dplyr::src_sqlite(paste(path.package("wakatimer"), ".wakatime.db", sep = "/"), create = FALSE)

  if (RCurl::url.exists("https://wakatime.com/api") &
      dplyr::db_has_table(.wakatimerEnv$db_con$con, "tmp")) {
    wt_post(local = TRUE)
    dplyr::db_drop_table(.wakatimerEnv$db_con$con,
                         "tmp")
  }

  dplyr::copy_to(
    dest = .wakatimerEnv$db_con,
    df   = recent_files() %>%
      dplyr::mutate(is_write = 0),
    name = ifelse(is.null(get_rproj_name()),
                  "heartbeats_1",
                  get_rproj_name()),
    temporary = FALSE
  )
}

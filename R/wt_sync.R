#' Sync file modify data as heartbeat
#' @importFrom httr add_headers
#' @importFrom httr POST
#' @name wt_sync
wt_sync <- function() {
  .wakatimerEnv$post.token <- write_scope()
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
        .wakatimerEnv$post.token$credentials$access_token
      ),
      `Content-Type`  = "application/json"
    ),
    body = file_info(),
    encode = "json"
  )
}

#' Sync modificate files between sesion
#' @import dplyr
#' @importFrom jsonlite toJSON
#' @importFrom rlist list.load
#' @name wt_sync_session
wt_sync_session <- function() {
  if (is.null(.wakatimerEnv$post.token))
    .wakatimerEnv$post.token <- write_scope()

  # .wakatimerEnv$df.files <- recent_files()
  .wakatimerEnv$df.files.load <-
    wakatimer:::record_files(df = .wakatimerEnv$df.files) %>%
    dplyr::mutate(is_write = FALSE)

  .wakatimerEnv$df.files.quit <-
    recent_files() %>% wakatimer:::record_files() %>%
    dplyr::bind_rows(.wakatimerEnv$df.files.load) %>%
    dplyr::distinct(time)

  .wakatimerEnv$exist.files <-
    .wakatimerEnv$df.files.quit %>% dplyr::filter(is_write == FALSE) %>% .$entity

  .wakatimerEnv$df.files.diff <- .wakatimerEnv$df.files.quit %>%
    dplyr::filter(entity %in% .wakatimerEnv$exist.files) %>%
    dplyr::arrange(time, entity) %>%
    dplyr::group_by(entity) %>%
    dplyr::summarise(status = lines[2] - lines[1]) %>%
    dplyr::mutate(status = ifelse((status == 0), status,
                                  ifelse((status > 1), paste0("+", status), status)))

  json.sync <- .wakatimerEnv$df.files.quit %>%
    dplyr::filter(entity %in% .wakatimerEnv$exist.files) %>%
    dplyr::arrange(time, entity) %>%
    dplyr::mutate(
      type = "file",
      lineno = NULL,
      cursorpos = NULL,
      project = wakatimer:::get_rproj_name(),
      branch = wakatimer:::get_hbranch_name(),
      language = gsub(".+\\.", "", entity),
      is_debugging = FALSE,
      is_write = ifelse(is.na(is_write), TRUE, FALSE)
    ) %>%
    jsonlite::toJSON(pretty = FALSE) %>%
    rlist::list.load()

  if (is.list(json.sync) & length(json.sync) >= 1)
    for (i in 1:length(json.sync)) {
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
            .wakatimerEnv$post.token$credentials$access_token
          ),
          `Content-Type`  = "application/json"
        ),
        body = json.sync[[i]],
        encode = "json"
      )
    }
}

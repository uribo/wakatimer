.wakatimerEnv <- new.env(parent = emptyenv())
.wakatimerEnv$post.token <- NULL
.wakatimerEnv$df.files <- NULL
.wakatimerEnv$df.files.quit <- NULL
.wakatimerEnv$df.files.diff <- NULL
.wakatimerEnv$exist.files <- NULL

.onAttach <- function(libname, pkgname) {
  if (!rstudioapi::isAvailable())
    warning("RStudio not running. This package only use RStudio.", call. = FALSE)

  packageStartupMessage(
    paste(
      if (.Platform$OS.type == "unix") {
        paste0(
          remoji::emoji("computer"),
          utils::sessionInfo()$R.version$language,
          " (",
          utils::sessionInfo()$R.version$major,
          ".",
          utils::sessionInfo()$R.version$minor,
          ")",
          remoji::emoji("large_blue_circle"),
          devtools::session_info()$platform$ui,
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
          " wakatimer (",
          utils::packageVersion("wakatimer"),
          ")"
        )
      },
      "Next, to run `write_scope()` and authentication for file status record :)",
      sep = "\n"
    )
  )
}

.onLoad <- function(libname, pkgname) {
  recent_files()
}

#' Authorize using OAuth 2.0 client token.
#' @description
#' If you not register application,
#'  create app and configure id and secret key from \href{https://wakatime.com/apps}{WakaTime}.
#' @param app.id character. OAuth app ID. If you set as system environment
#' (recommend) variables is used (check \code{Sys.setenv('WAKATIME_ID')}).
#' @param app.secret character. OAuth secret app key. If you set as system environment
#' @importFrom httr oauth2.0_token
#' @name write_scope
#' @export
write_scope <-
  function(app.id = Sys.getenv("WAKATIME_ID"),
           app.secret = Sys.getenv("WAKATIME_SECRET")) {
    .wakatimerEnv$post.token <-
      httr::oauth2.0_token(
        endpoint = httr::oauth_endpoint(
          access = "https://wakatime.com/oauth/token",
          authorize = "https://wakatime.com/oauth/authorize",
          base_url = "https://api.wakatime.com/api/v1"
        ),
        app = httr::oauth_app(
          appname = "wakatimer",
          key = app.id,
          secret = app.secret
        ),
        scope = "write_logged_time"
      )
    .Last <<- function() {
      if (is.null(.wakatimerEnv$post.token))
        .wakatimerEnv$post.token <- write_scope()
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
                                      ifelse((status > 1), paste0("+", status), status
                                      )))

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
  }

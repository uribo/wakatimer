#' generate oauth token
#' @param app.id character. OAuth app ID. If you set as system environment
#' (recommend) variables is used (check \code{Sys.setenv('WAKATIME_ID')}).
#' @param app.secret character. OAuth secret app key. If you set as system environment
#' @name gen_token
#' @export
gen_token <- function(app.id = Sys.getenv("WAKATIME_ID"),
                      app.secret = Sys.getenv("WAKATIME_SECRET")) {
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
    .wakatimerEnv$post.token <- gen_token(app.id, app.secret)

    if (!file.exists(paste(path.package("wakatimer"), ".wakatime.db", sep = "/")))
      dplyr::src_sqlite(paste(path.package("wakatimer"), ".wakatime.db", sep = "/"), create = TRUE)

    .Last <<- function() {
      if (RCurl::url.exists("https://wakatime.com/api")) {
        wt_post()
      } else {
        wt_sync_local()
      }
    }
    wt_sync_session()
    msg_ver()
  }

#' wakatime api wrapper
#' @param resource select request api resource type
#' @param key character. your wakatime api key
#' @param param request url parameters provide as list.
#' @importFrom httr GET
#' @importFrom httr stop_for_status
#' @importFrom jsonlite fromJSON
#' @name wt_api
wt_api <-
  function(resource = c("heartbeats",
                        "durations",
                        "stats",
                        "users",
                        "summaries",
                        "user_agents"),
           key = Sys.getenv("WAKATIME_KEY"),
           param = list(date = format(Sys.Date(), "%m/%d/%Y"),
                        time = "time",
                        "entity")) {
    if (!is.null(param$date))
      param = paste0("date=", param %>% unlist() %>% paste(collapse = "&"))

    if (resource == "users")
      resource = NULL

    req <- httr::GET(
      url = "https://wakatime.com/",
      path = paste0(
        "api/v1/users/current/",
        resource,
        "?api_key=",
        key,
        "&",
        param
      ),
      encode = "json"
    )

    httr::stop_for_status(req)

    jsonlite::fromJSON(req$url) %>% return()
  }

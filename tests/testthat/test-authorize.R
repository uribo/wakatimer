context("Authorize to WakaTime")
key <- Sys.getenv("WAKATIME_KEY")

test_that("internet_connection", {
  testthat::expect_true(RCurl::url.exists("https://wakatime.com/api"))
})

# resource, key, param
test_that("api-endpoint-durations", {
  resource <- "durations"
  param <- list(
    date = format(Sys.Date(), "%m/%d/%Y"),
    project = "wakatimer",
    branches = "master"
  ) %>%
    paste(names(.), ., sep = "=") %>%
    unlist() %>%
    paste(collapse = "&")

  expect_equal(
    httr::GET(
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
    ) %>% httr::status_code(),
    200L
  )
})

# resource, key, param
test_that("api-endpoint-heartbeats-get", {
  resource <- "heartbeats"
  param <- list(date = format(Sys.Date(), "%m/%d/%Y")) %>%
    paste(names(.), ., sep = "=") %>%
    unlist() %>%
    paste(collapse = "&")

  expect_equal(
    httr::GET(
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
    ) %>% httr::status_code(),
    200L
  )
})

# test_that("oauth_login", {
#   unlockBinding('interactive', as.environment('package:base'))
#   assign('interactive', function() TRUE, envir = as.environment('package:base'))
#   expect_equal(
#     stop(menu(write_scope()))
#     , is.null())
# })

test_that("api-endpoint-stats", {
  resource <- "stats"
  param <- list(range = "last_7_days",
                project = "wakatimer") %>%
    paste(names(.), ., sep = "=") %>%
    unlist() %>%
    paste(collapse = "&")

  expect_equal(
    httr::GET(
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
    ) %>% httr::status_code(),
    200L
  )
})

test_that("api-endpoint-summaries", {
  resource <- "summaries"
  param <- list(
    start = format(Sys.Date() - 7, "%m/%d/%Y"),
    end   = format(Sys.Date(), "%m/%d/%Y"),
    project = "wakatimer"
  ) %>%
    paste(names(.), ., sep = "=") %>%
    unlist() %>%
    paste(collapse = "&")

  expect_equal(
    httr::GET(
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
    ) %>% httr::status_code(),
    200L
  )
})

test_that("api-endpoint-users", {
  resource <- NULL

  expect_equal(
    httr::GET(
      url = "https://wakatime.com/",
      path = paste0("api/v1/users/current/",
                    resource,
                    "?api_key=",
                    key),
      encode = "json"
    ) %>% httr::status_code(),
    200L
  )
})

test_that("api-endpoint-user_agents", {
  resource <- "user_agents"

  expect_equal(
    httr::GET(
      url = "https://wakatime.com/",
      path = paste0("api/v1/users/current/",
                    resource,
                    "?api_key=",
                    key),
      encode = "json"
    ) %>% httr::status_code(),
    200L
  )
})

test_that("api-endpoint-leaders", {
  resource <- "leaders"
  # param <- list(language = "r") %>%
  #   paste(names(.), ., sep = "=") %>%
  #   unlist() %>%
  #   paste(collapse = "&")

  expect_equal(
    httr::GET(
      url = "https://wakatime.com/",
      path = paste0("api/v1/",
                    resource),
      encode = "json"
    ) %>% httr::status_code(),
    200L
  )
})


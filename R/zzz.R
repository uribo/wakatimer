.wakatimerEnv <- new.env(parent = emptyenv())
.wakatimerEnv$post.token <- NULL
.wakatimerEnv$df.files <- NULL
.wakatimerEnv$db_con <- NULL

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("Next, to run `write_scope()` and authentication for file status record :)")
}

.onLoad <- function(libname, pkgname) {
  recent_files()
}

#' change a function's default arguments
#' @name default
#' @export
#'
#' @description \code{default()} lets you check, and change, a function's
#'   default arguments. \code{reset_default()} returns the arguments to their
#'   original defaults.
#'
#' @param fun a function
#' @param value a named list of new default arguments for that function
#'
#' @details If \code{fun} is a function from a package, a function of the same
#'   name will be defined in the calling environment (e.g. your workspace).
#'   If \code{fun} is defined locally, it will be overwritten by the version
#'   with the new defaults.
#'
#'   \code{reset_default} \emph{returns} the reset function, rather than
#'   modifying it in place, so you'll need to reassign it, as in the example.
#'
#' @return \code{default()} (without assignment) invisibly returns a pairlist of
#'   the current values of the default arguments. It also prints the default
#'   arguments, highlighting those that the user has changed from their original
#'   defaults.
#'
#'   \code{reset_default()} returns the \code{fun}, but with the defaults reset
#'   to their original values. If \code{fun} was a function from a package, the
#'   same thing can be achieved by replacing the locally-defined version of the
#'   function.
#'
#' @examples
#' # list the default arguments for a function
#' default(data.frame)
#'
#' # change one or more of them
#' default(data.frame) <- list(fix.empty.names = FALSE)
#' data.frame(1:3)
#'
#' # reset the defaults
#' data.frame <- reset_default(data.frame)
#' data.frame(1:3)
default <- function (fun) {
  check_function(fun)
  args <- formals(fun)
  render_defaults(args, fun)
  invisible(args)
}

#' @rdname default
#' @export
`default<-` <- function (fun, value) {

  check_function(fun)
  check_defaults(value, fun)

  arguments <- update_defaults(formals(fun), value)

  new_fun <- do.call(`function`,
                     list(arguments,
                          body(fun)),
                     envir = environment(fun))

  original(new_fun) <- reset_default(fun)

  class(new_fun) <- c("defaults_function", class(new_fun))

  new_fun

}

#' @rdname default
#' @export
reset_default <- function (fun) {

  original_fun <- original(fun)

  if (is.null(original_fun))
    original_fun <- fun

  original_fun

}

original <- function (fun)
  attr(fun, "original_function")

`original<-` <- function (fun, value)
  `attr<-`(fun, "original_function", value)

# print the function without the original function as an attribute
#' @export
print.defaults_function <- function (x, ...) {

  original(x) <- NULL

  print.function(x, ...)

}

# print the current default arguments nicely
render_defaults <- function (args, fun) {

  if (length(args) == 0) {

    cat("function has no arguments")
    return ()

  }

  each_default_text <- lapply(seq_along(args), render_one_default, args)

  # if it has overwritten defaults, mark them with an asterisk
  if (inherits(fun, "defaults_function"))
    updated <- !mapply(identical, args, formals(original(fun)))
  else
    updated <- FALSE

  prepend <- ifelse(updated, "* - ", "  - ")
  each_default_text <- paste0(prepend, each_default_text)

  defaults_text <- paste(each_default_text, collapse = "\n")
  cat(defaults_text, "\n")

}

#' @importFrom utils capture.output
render_one_default <- function (index, args) {

  name <- names(args[index])
  value <- args[[index]]

  if (missing(value))
    value <- "[none]"
  else if (is.character(value))
    value <- paste0('"', value, '"')

  if (is.null(value))
    value <- "NULL"

  if (is.call(value))
    value <- capture.output(print(value))

  paste(name, value, sep = " = ")

}

check_function <- function (fun) {

  if (!is.function(fun))
    stop ("fun is not a function",
          call. = FALSE)

  if (is.primitive(fun))
    stop ("fun is a primitive function; its default arguments cannot be altered",
          call. = FALSE)

}

check_defaults <- function (value, fun) {

  if (!is.list(value))
    stop ("value is not a list",
          call. = FALSE)

  if (any(names(value) == ""))
    stop ("not all of the new default arguments are named",
          call. = FALSE)

  old_args <- names(formals(fun))
  new_args <- names(value)
  bad_args <- new_args[!new_args %in% old_args]

  if (length(bad_args) > 0) {

    bad_args <- paste0("'", bad_args, "'")

    if (length(bad_args) == 1) {
      msg <- paste(bad_args,
                   "is not an argument of this function")
    } else {
      msg <- paste(paste(bad_args, collapse = ", "),
                   "are not arguments of this function")
    }

    stop (msg, call. = FALSE)

  }

}

update_defaults <- function (old_defaults, new_defaults) {

  old_defaults[names(new_defaults)] <- new_defaults

  as.pairlist(old_defaults)

}

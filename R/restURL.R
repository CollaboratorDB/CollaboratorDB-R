#' Get/set the CollaboratorDB REST URL
#'
#' Pretty much as the title says.
#'
#' @param url String containing the REST URL to use.
#'
#' @return If \code{url} is not supplied, the currently set URL is returned.
#'
#' If \code{url} is supplied, it is used to set the URL, and the \emph{previously} set value of the URL is returned.
#'
#' @author Aaron Lun
#' 
#' @examples
#' restURL()
#'
#' old <- restURL("https://new.url.com")
#' restURL()
#' restURL(old)
#' 
#' @export    
restURL <- function(url) {
    prev <- globals$rest.url
    if (missing(url)) {
        prev
    } else {
        globals$rest.url <- url
        invisible(prev)
    }
}

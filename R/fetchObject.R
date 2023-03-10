#' Fetch an object from the CollaboratorDB backend
#'
#' Fetch an object from the CollaboratorDB backend.
#' This involves caching its associated files before loading it into the current R session.
#'
#' @param id String containing the ArtifactDB identifier for the object of interest.
#' @param cache Logical scalar indicating whether caching should be performed.
#' If \code{TRUE}, a default cache location is chosen.
#'
#' Alternatively, a string specifying the path to a cache directory.
#'
#' Alternatively, a \linkS4class{BiocFileCache} object.
#' @param force.update Logical scalar indicating whether cache entries should be forcibly updated.
#' Useful for fixing corrupted or incomplete files in the cache.#'
#'
#' @return
#' An R object corresponding to \code{id}.
#'
#' @author Aaron Lun
#'
#' @examples
#' cache.dir <- tempfile()
#' id <- exampleID()
#'
#' # First request downloads the resources:
#' obj <- fetchObject(id, cache=cache.dir)
#' obj
#'
#' # Next query just uses the cache:
#' fetchObject(id, cache=cache.dir)
#'
#' # All the annotation is attached:
#' str(objectAnnotation(obj))
#' 
#' @seealso
#' \code{\link{saveObject}} and \code{\link{uploadDirectory}}, to save and upload objects to the CollaboratorDB backend.
#'
#' @export
#' @importFrom alabaster.base acquireMetadata .altLoadObject
#' @importFrom zircon unpackID
fetchObject <- function(id, cache=TRUE, force.update=FALSE) {
    cfun <- .configure_cache(cache, force.update=force.update)
    on.exit(cfun(), add=TRUE)

    ifun <- .setup_github_identities()
    on.exit(ifun(), add=TRUE)

    oldl <- .altLoadObject(cdbLoadObject)
    on.exit(.altLoadObject(oldl), add=TRUE)

    unpacked <- unpackID(id)
    proj <- new("CollaboratorDBHandler", project=unpacked$project, version=unpacked$version)
    meta <- acquireMetadata(proj, unpacked$path)

    cdbLoadObject(meta, proj)
}

#' @importFrom BiocFileCache BiocFileCache
.configure_cache <- function(cache=TRUE, force.update=FALSE) {
    oldc <- globals$cache.object
    oldu <- globals$cache.update

    if (isFALSE(cache)) {
        globals$cache.object <- NULL
    } else if (is.character(cache)) {
        globals$cache.object <- BiocFileCache(cache, ask=FALSE)
    } else if (isTRUE(cache)) {
        dir <- file.path(.cache_directory(), "contents")
        dir.create(dirname(dir), showWarnings=FALSE, recursive=TRUE)
        globals$cache.object <- BiocFileCache(dir, ask=FALSE)
    } else {
        if (!is(cache, "BiocFileCache")) {
            stop("'cache' should be a string, logical scalar, or a BiocFileCache")
        }
        globals$cache.object <- cache
    }
    globals$cache.update <- force.update

    invisible(function() {
        globals$cache.object <- oldc
        globals$cache.update <- oldu
    })
}

schema.memory <- new.env()
schema.memory$cache <- list()

#' @import CollaboratorDB.schemas 
#' @importFrom alabaster.base .loadObjectInternal
cdbLoadObject <- function(info, project, ...) {
    obj <- .loadObjectInternal(info, project, ..., .locations="CollaboratorDB.schemas", .memory=schema.memory)

    if (is(obj, "Annotated")) {
        blessed <- c(
            "title", 
            "description", 
            "authors",
            "species",
            "genome",
            "origin",
            "terms",
            "_extra"
        )
        obj <- setAnnotation(obj, info[intersect(names(info), blessed)])
    }

    obj
}

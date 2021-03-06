BASE_URL <- "https://boe.es/"
JOURNAL_URL <- c(BORME = "diario_borme", BOE = "diario_boe")



#' Build a query for an XML
#'
#' @param id The id of the xml document you want.
#' @return A query for the xml.
#' @seealso [sumario_nbo()]
#' @export
#' @examples
#' id <- sumario_nbo(format(as.Date("2017/10/02", "%Y/%m/%d"), "%Y%m%d"))
#' cve <- sumario_cve("2017", "237") # Same document but by the CVE
#' query_xml(id)
#' query_xml(cve)
#' @importFrom httr modify_url
query_xml <- function(id) {
    check_code(id)
    force(BASE_URL)
    force(JOURNAL_URL)
    journal <- strsplit(id, split = "-", fixed = TRUE)[[1]][1]
    journal <- match.arg(journal, c("BOE", "BORME"))
    httr::modify_url(BASE_URL,
                     path = paste0(JOURNAL_URL[journal], "/xml.php"),
                     query = paste0("id=", id))
}



#' Build a query for the webpage
#'
#' @param cve The CVE of the document you want.
#' @return  A query url.
#' @seealso query_consolidada
#' @export
#' @examples
#' cve <- sumario_cve("2017", "117")
#' query_htm(cve)
query_htm <- function(cve) {
    check_code(cve)
    force(BASE_URL)
    force(JOURNAL_URL)
    journal <- strsplit(cve, "-", fixed = TRUE)[[1]][1]
    httr::modify_url(BASE_URL,
                     path = paste0(JOURNAL_URL[journal], "/text.php"),
                     query = paste0("id=", cve))
}

#' Build a query for the webpage
#'
#' Look for the consolidated law online
#' @param cve The CVE of the document you want.
#' @return  A query url.
#' @export
#' @examples
#' cve <- disposicion_cve("2017", "117")
#' query_consolidada(cve)
query_consolidada <- function(cve) {
    check_code(cve)
    force(BASE_URL)
    ids <- strsplit(cve, "-", fixed = TRUE)[[1]]
    if (ids[2] != "A") {
        stop("Documents with BOE-A-*", call. = FALSE)
    }

    if (ids[1] != "BOE") {
        stop("This is only for laws on the BOE.", call. = FALSE)
    }
    httr::modify_url(BASE_URL,
                     path = "buscar/act.php",
                     query = paste0("id=", cve))
}

#' Query a pdf from the BOE
#'
#' To query a pdf you must know the number of the piece you are looking for and
#' the date it was published.
#' @param year Character of the number of the year: YYYY
#' @param month Character of the number of the month: MM.
#' @param day Character of the number of the day: DD.
#' @param code Code of the publication to query.
#' @return A link to the pdf.
#' @export
#' @examples
#' cve <- sumario_cve("2017", "237")
#' query_pdf("2017", "10", "02", cve)
query_pdf <- function(year, month, day, code) {
    vapply(code, check_code, logical(1))
    force(BASE_URL)
    journal <- tolower(gsub("-.*", "", code))
    p <- paste(journal, "dias", year, month, day, "pdfs", paste0(code, ".pdf"), sep = "/")
    paste0(BASE_URL, path = p)
}

#' Retrieve the XML content
#'
#' Look up on the internet and get the content
#' @param query A query to BOE.
#' @seealso [query_xml()]
#' @importFrom httr content
#' @importFrom httr GET
#' @importFrom httr user_agent
#' @importFrom httr status_code
#' @importFrom httr http_type
#' @importFrom httr stop_for_status
#' @export
#' @examples
#' id <- sumario_nbo(format(as.Date("2017/10/02", "%Y/%m/%d"), "%Y%m%d"))
#' url <- query_xml(id)
#' \donttest{get_xml(url)}
get_xml <- function(query) {
    user_agent <- user_agent("https://github.com/llrs/BOE")
    response <- GET(query, user_agent)
    httr::stop_for_status(response)
    if (status_code(response) != 200) {
        stop("Could not retrieve the data.", call. = FALSE)
    }
    if (http_type(response) == "text/html") {
        warning("Missing data.", call. = FALSE)
    }
    if (http_type(response) != "application/xml") {
        stop("API did not find the requested document.", call. = FALSE)
    }
    content(response)
}

  # Helper function to add or retrieve reference
add_reference <- function(ref_list, reference_text, 
                          PMID = NA_character_, 
                          DOI = NA_character_) {
  ## R CMD check errors ##
  .data <- NULL
  ## End R CMD check errors ##

  # Early exit for invalid input
  if (is.na(reference_text) || reference_text == "" || is.null(reference_text)) {
    return(list(ref_list = ref_list, ref_id = NA_integer_))
  }
  
  # Convert to tibble if needed (defensive conversion)
  if (!is.data.frame(ref_list)) {
    # If it's not a data frame at all, initialize empty refs table
    ref_list <- tibble::tibble(
      ref_id = integer(),
      Reference = character(),
      PMID = character(),
      DOI = character()
    )
  } else {
    # Ensure it's a tibble with correct structure
    ref_list <- tibble::as_tibble(ref_list)
    # Check that required columns exist
    if (!all(c("ref_id", "Reference") %in% names(ref_list))) {
      ref_list <- tibble::tibble(
        ref_id = integer(),
        Reference = character(),
        PMID = character(),
        DOI = character()
      )
    }
  }
    
    # Check if reference already exists (with explicit error handling)
    tryCatch({
      # Use filter safely with explicit column selection
      existing <- ref_list %>%
        dplyr::filter(.data$Reference == !!reference_text)
      
      # Verify result is a proper data frame with at least one row
      if (is.data.frame(existing) && nrow(existing) > 0) {
        ref_id_val <- existing$ref_id[1]
        if (!is.na(ref_id_val)) {
          return(list(ref_list = ref_list, ref_id = ref_id_val))
        }
      }
    }, error = function(e) {
      # If filter fails, return NA_integer_
      return(list(ref_list = ref_list, ref_id = NA_integer_))
    })
    
    # Add new reference
    new_ref_id <- get_next_id(ref_list, "ref_id")
    new_ref <- tibble::tibble(
      ref_id = new_ref_id,
      Reference = reference_text,
      PMID = PMID,
      DOI = DOI
    )
    list(ref_list = dplyr::bind_rows(ref_list, new_ref), 
         ref_id = new_ref_id)
  }

  # Helper function to get next ID
  get_next_id <- function(df, id_col) {
    if (nrow(df) == 0) return(1L)
    return(max(df[[id_col]], na.rm = TRUE) + 1L)
  }
  
  root <- getwd()
  data_dir <- "data"
  db_path <- "db"
  ivivedb <- normalizePath(file.path(root, paste0(db_path,"/ivive.db")))
  
  query_reference <- function(ref_ids
  )
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    # Load HTTK Css predictions:
    qry <- paste0("
    SELECT *
	  FROM CITK.refs
	  WHERE ref_id IN (\'",
                  paste(sort(ref_ids),collapse="\',\'"),
                  "\');
    ")
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_invivodb <- function(chem.list,
                             search.col="DTXSID"
  )
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    # Load HTTK Css predictions:
    qry <- paste0("
    SELECT *
	  FROM CITK.invivo
	  INNER JOIN CITK.chemicals ON invivo.chem_id_fk=chemicals.chem_id
	  LEFT JOIN CITK.refs on invivo.ref_id_fk = refs.ref_id
	  WHERE ", search.col, " IN (\'",
                  paste(sort(chem.list),collapse="\',\'"),
                  "\');
    ")
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_ivivedb <- function(chem.list,
                            uncertainty = TRUE,
                            variability = TRUE,
                            search.col="DTXSID"
  )
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    qry <- paste0("
    SELECT *
	  FROM CITK.ivive
	  INNER JOIN CITK.chemicals ON ivive.chem_id_fk=chemicals.chem_id
	  LEFT JOIN CITK.models ON ivive.model_id_fk = models.model_id
	  INNER JOIN CITK.cohorts ON ivive.cohort_id_fk=cohorts.cohort_id
	  INNER JOIN CITK.routes ON ivive.route_id_fk=routes.route_id
	  LEFT JOIN CITK.refs on ivive.ref_id_fk = refs.ref_id
	  WHERE ", search.col, " IN (\'",
                  paste(sort(chem.list),collapse="\',\'"),
                  "\')",
                  ifelse(!is.na(uncertainty),
                         paste0(" AND cohorts.Uncertainty = ",
                                uncertainty),
                         ""),
                  ifelse(!is.na(variability),
                         paste0(" AND cohorts.Variability = ",
                                variability),
                         ""),
                  ";
    ")
    
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_httkdb <- function(chem.list,
                           search.col="DTXSID"
  )
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    qry <- paste0("
    SELECT *
	  FROM CITK.httk
	  INNER JOIN CITK.chemicals ON httk.chem_id_fk=chemicals.chem_id
	  LEFT JOIN CITK.models ON httk.model_id_fk = models.model_id
	  LEFT JOIN CITK.refs on httk.ref_id_fk = refs.ref_id
	  WHERE ", search.col, " IN (\'",
                  paste(sort(chem.list),collapse="\',\'"),
                  "\');
    ")
    
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_invitrotkdb <- function(chem.list,
                                search.col="DTXSID"
  )
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    qry <- paste0("
    SELECT *
	  FROM CITK.invitrotk
	  INNER JOIN CITK.chemicals ON invitrotk.chem_id_fk=chemicals.chem_id
	  LEFT JOIN CITK.refs on invitrotk.ref_id_fk = refs.ref_id
	  WHERE ", search.col, " IN (\'",
                  paste(sort(chem.list),collapse="\',\'"),
                  "\');
    ")
    
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_chemprops <- function(chem.list,
                              search.col="DTXSID")
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    # Get molecular weight:
    qry <- paste0("
    SELECT DTXSID, Property, Value 
	  FROM CITK.chemprop
	  INNER JOIN CITK.chemicals ON chemprop.chem_id_fk=chemicals.chem_id
	  WHERE ", search.col, " IN (\'",
                  paste(sort(chem.list),collapse="\',\'"),
                  "\');
    ")
    
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_cheminfo <- function(chem.list,
                             search.col="DTXSID")
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    # Get molecular weight:
    qry <- paste0("
    SELECT * 
	  FROM CITK.chemicals
	  WHERE ", search.col, " IN (\'",
                  paste(sort(chem.list),collapse="\',\'"),
                  "\');
    ")
    
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_countrows<- function(table)
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    # Get molecular weight:
    qry <- paste0("
    SELECT COUNT(*) FROM CITK.",
                  table,";")
    
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_countchems <- function(table)
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    # Get molecular weight:
    qry <- paste0("
    SELECT COUNT(DISTINCT chem_id_fk) AS unique_count
    FROM CITK.",
                  table,";")
    
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
  query_countrefs <- function(table)
  {
    con <- duckdb::dbConnect(
      duckdb::duckdb(),
      dbdir = ivivedb,
      read_only = TRUE
    )
    
    # Get molecular weight:
    qry <- paste0("
    SELECT COUNT(DISTINCT ref_id_fk) AS unique_count
    FROM CITK.",
                  table,";")
    
    out <- dbGetQuery(con, qry)  
    
    duckdb::dbDisconnect(con, shutdown = TRUE)
    
    return(out)
  }
  
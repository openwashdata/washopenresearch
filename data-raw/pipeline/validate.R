# The validation gate: every built dataset passes through validate_dataset()
# before anything is written. A dataset that breaks a rule stops the build,
# with every broken rule named in one message.

# The column that identifies an article in a dataset.
dataset_key <- function(name) {
  if (name %in% c("ploswater", "datapapers")) "doi" else "paperid"
}

# Datasets that no acquisition updates any more, with their row counts.
frozen_row_counts <- function() {
  c(uncnewsletter = 173L, datapapers = 8L)
}

# The dataset as shipped in the last release, or NULL when that release did
# not have it. Read from git, without touching the working tree.
released_dataset <- function(name) {
  tag <- suppressWarnings(
    system2("git", c("describe", "--tags", "--abbrev=0"), stdout = TRUE, stderr = FALSE)
  )
  if (!is.null(attr(tag, "status")) || length(tag) != 1) {
    stop(
      "No release tag found, so the gate cannot tell whether an article ",
      "was lost since the last release. Fetch the tags (git fetch --tags).",
      call. = FALSE
    )
  }
  path <- tempfile(fileext = ".rda")
  on.exit(unlink(path))
  status <- system2(
    "git", c("show", sprintf("%s:data/%s.rda", tag, name)),
    stdout = path, stderr = FALSE
  )
  if (status != 0) {
    return(NULL)
  }
  released <- new.env()
  load(path, envir = released)
  released[[name]]
}

# The values of every text column and the levels of every factor column: all
# the free text of a dataset, as one named list.
dataset_text <- function(data) {
  text <- lapply(data, function(column) {
    if (is.character(column)) column else if (is.factor(column)) levels(column) else NULL
  })
  text[!vapply(text, is.null, logical(1))]
}

# Names of the columns in which any text value matches `pattern`.
columns_matching <- function(data, pattern) {
  text <- dataset_text(data)
  hits <- vapply(text, function(x) any(grepl(pattern, x, perl = TRUE)), logical(1))
  names(text)[hits]
}

# The rules. Each takes the dataset and the gate's context and returns one
# message per violation, or character(0).
gate_rules <- function() {
  list(
    dictionary_columns = function(data, context) {
      documented <- context$dictionary$variable_name[
        context$dictionary$file_name == paste0(context$name, ".rda")
      ]
      c(
        if (length(setdiff(names(data), documented)) > 0) {
          paste("columns missing from the data dictionary:",
                paste(setdiff(names(data), documented), collapse = ", "))
        },
        if (length(setdiff(documented, names(data))) > 0) {
          paste("data dictionary columns missing from the dataset:",
                paste(setdiff(documented, names(data)), collapse = ", "))
        }
      )
    },
    unique_key = function(data, context) {
      key <- data[[context$key]]
      repeated <- unique(key[duplicated(key)])
      if (anyNA(key)) {
        paste0("missing values in the key column ", context$key)
      } else if (length(repeated) > 0) {
        paste0(length(repeated), " repeated ", context$key, " values: ",
               paste(utils::head(repeated, 5), collapse = ", "))
      }
    },
    no_list_columns = function(data, context) {
      lists <- names(data)[vapply(data, is.list, logical(1))]
      if (length(lists) > 0) paste("list columns:", paste(lists, collapse = ", "))
    },
    no_email_columns = function(data, context) {
      emails <- grep("email", names(data), ignore.case = TRUE, value = TRUE)
      if (length(emails) > 0) paste("email columns:", paste(emails, collapse = ", "))
    },
    no_inline_addresses = function(data, context) {
      columns <- columns_matching(data, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
      if (length(columns) > 0) {
        paste("email addresses inside the text of:", paste(columns, collapse = ", "))
      }
    },
    no_access_tokens = function(data, context) {
      # A token, access_token or signature parameter that strip_url_tokens()
      # did not drop.
      columns <- columns_matching(data, "[?&](token|access_token|signature)[=]")
      if (length(columns) > 0) {
        paste("access tokens in URLs of:", paste(columns, collapse = ", "))
      }
    },
    no_stated_passwords = function(data, context) {
      columns <- columns_matching(data, "(?i)(password|passcode)\\s*[:=]")
      if (length(columns) > 0) {
        paste("passwords stated in the text of:", paste(columns, collapse = ", "))
      }
    },
    statement_text = function(data, context) {
      if (!all(c("has_das", "das") %in% names(data))) {
        return(NULL)
      }
      without_text <- sum(data$has_das %in% TRUE & is.na(data$das))
      if (without_text > 0) {
        paste(without_text, "articles flagged as having a data availability",
              "statement have no statement text")
      }
    },
    un_country_names = function(data, context) {
      columns <- grep("affiliation_country$", names(data), value = TRUE)
      values <- unique(unlist(data[columns], use.names = FALSE))
      unknown <- setdiff(values[!is.na(values)], context$un_names)
      if (length(unknown) > 0) {
        paste("country values that are not UN names:",
              paste(utils::head(unknown, 10), collapse = ", "))
      }
    },
    frozen_row_count = function(data, context) {
      expected <- frozen_row_counts()[context$name]
      if (!is.na(expected) && nrow(data) != expected) {
        paste0("frozen dataset has ", nrow(data), " rows, expected ", expected)
      }
    },
    no_lost_keys = function(data, context) {
      if (is.null(context$released)) {
        return(NULL)
      }
      allowed <- context$removed_keys$key[context$removed_keys$dataset == context$name]
      lost <- setdiff(
        as.character(context$released[[context$key]]),
        c(as.character(data[[context$key]]), allowed)
      )
      if (length(lost) > 0) {
        paste0(length(lost), " articles of the last release are gone and not ",
               "listed in the removed-keys sheet: ",
               paste(utils::head(lost, 5), collapse = ", "))
      }
    }
  )
}

# Rules the data shipped in v0.4.0 breaks. Each is switched on by the commit
# that fixes its defect, and this list goes when it is empty.
rules_awaiting_fixes <- function() {
  c("no_inline_addresses")
}

# Validate a built dataset. Returns it unchanged when every rule holds and
# stops otherwise. `released` is the dataset as last released (NULL for a
# new dataset); it is an argument so the rule can be tested without git.
validate_dataset <- function(data, name, dictionary_file, removed_keys_file,
                             released = released_dataset(name),
                             skip = rules_awaiting_fixes()) {
  context <- list(
    name = name,
    key = dataset_key(name),
    dictionary = read_strict_csv(
      dictionary_file, readr::cols(.default = readr::col_character())
    ),
    removed_keys = read_strict_csv(
      removed_keys_file, readr::cols(.default = readr::col_character())
    ),
    un_names = unique(countries::country_reference_list$UN_en),
    released = released
  )
  rules <- gate_rules()
  rules <- rules[setdiff(names(rules), skip)]
  violations <- unlist(lapply(rules, function(rule) rule(data, context)))
  if (length(violations) > 0) {
    stop(
      "Dataset '", name, "' failed validation:\n",
      paste0("- ", names(violations), ": ", violations, collapse = "\n"),
      call. = FALSE
    )
  }
  data
}

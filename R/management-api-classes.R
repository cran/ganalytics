#' @include GaApiRequest.R
#' @include ga-api-classes.R
#' @importFrom R6 R6Class
#' @importFrom plyr ldply alply mutate

.gaManagementApi <- R6Class(
  ".gaManagementApi",
  inherit = .googleApi,
  private = list(
    scope = ga_scopes['read_only'],
    write_scope = ga_scopes["edit"],
    api_req_func = function(request, ...){
      request <- c(
        "management",
        "upload"[attr(request, "upload")],
        request
      )
      ga_api_request(request = request, ...)
    },
    base_url = "https://www.googleapis.com/analytics/v3"
  )
)

gaResource <- R6Class(
  "gaResource",
  inherit = .googleApiResource,
  private = get_privates(.gaManagementApi)
)

gaCollection <- R6Class(
  "gaCollection",
  inherit = .googleApiCollection,
  private = get_privates(.gaManagementApi)
)

#' @export
`[.gaCollection` <- function(x, i) {x$entities[i]}

#' @export
`[[.gaCollection` <- function(x, i) {x$entities[[i]]}

gaUserSegment <- R6Class(
  "gaUserSegment",
  inherit = gaResource,
  public = list(
    type = NA,
    segmentId = NA,
    definition = NA,
    get = function() {
      if (!is.null(self$.req_path)) {
        user_segment_fields <- subset(
          gaUserSegments$new(creds = self$creds)$summary,
          subset = id == self$id
        )
        self$modify(user_segment_fields)
      }
      self
    },
    UPDATE = NULL,
    print = function(...) {
      super$print(...)
      cat("  $type       = ", self$type, "\n")
      cat("  $segmentId  = ", self$segmentId, "\n")
      cat("  $definition = ", self$definition, "\n")
    }
  ),
  active = list(
    api_list = function(){
      c(super$api_list, list(
        type = self$type,
        segmentId = self$segmentId,
        definition = self$definition
      ))
    }
  ),
  private = list(
    parent_class_name = "NULL",
    request = "segments",
    field_corrections = function(field_list) {
      field_list <- super$field_corrections(field_list)
      mutate(
        field_list,
        type = factor(type, levels = user_segment_type_levels)
      )
    }
  )
)

#' User Segments
#'
#' Get a user or system defined segment.
#'
#' @param id ID of the user or system segment to get
#' @param definition The definition to use if an ID is not provided.
#' @param creds The Google APIs credentials to use.
#'
#' @export
GaUserSegment <- function(id = NULL, definition = NA, creds = get_creds()){
  id <- sub("^gaid::", "", id)
  userSegment <- gaUserSegment$new(id = id, creds = creds)
  if (is.null(id)) {
    userSegment$definition <- definition
  }
  userSegment
}

gaUserSegments <- R6Class(
  "gaUserSegments",
  inherit = gaCollection,
  public = list(
    INSERT = NULL,
    DELETE = NULL
  ),
  private = list(
    entity_class = gaUserSegment,
    field_corrections = gaUserSegment$private_methods$field_corrections
  )
)

#' Get a collection of user and system defined segments.
#'
#' Returns a collection object of user and system defined segments available
#' under the supplied user credentials.
#'
#' @param creds The Google APIs credentials to use.
#'
#' @export
GaUserSegments <- function(creds = get_creds()){
  gaUserSegments$new(creds = creds)
}

gaAccountSummary <- R6Class(
  "gaAccountSummary",
  inherit = gaResource,
  public = list(
    webProperties = NULL,
    get = function() {
      if (!is.null(self$.req_path)) {
        account_summary_fields <- subset(
          gaAccountSummaries$new(creds = self$creds)$summary,
          subset = id == self$id
        )
        self$modify(account_summary_fields)
      }
      self
    },
    UPDATE = NULL
  ),
  active = list(
    summary = function() {
      webProperties <- self$webProperties
      if (is.null(webProperties)) return(data.frame())
      if (!is.data.frame(webProperties)) webProperties <- webProperties[[1]]
      adply(webProperties, 1, function(webPropertySummary) {
        property_df <- data.frame(
          propertyId = webPropertySummary$id,
          propertyName = webPropertySummary$name,
          level = webPropertySummary$level,
          websiteUrl = webPropertySummary$websiteUrl
        )
        adply(webPropertySummary$profiles, 1, function(viewSummary) {
          view_df <- data.frame(
            viewId = viewSummary$id,
            viewName = viewSummary$name,
            viewType = viewSummary$type
          )
          cbind(property_df, view_df)
        }, .expand = FALSE, .id = NULL)
      }, .expand = FALSE, .id = NULL)
    }
  ),
  private = list(
    parent_class_name = "NULL",
    request = "accountSummaries",
    field_corrections = function(field_list) {
      field_list <- super$field_corrections(field_list)
    }
  )
)

#' GA Account Summary
#'
#' Get a Google Analytics account summary resource.
#'
#' @param id ID of the GA account to get a summary of.
#' @param creds The Google APIs credentials to use.
#'
#' @export
GaAccountSummary <- function(id = NULL, creds = get_creds()){
  gaAccountSummary$new(id = id, creds = creds)
}

gaAccountSummaries <- R6Class(
  "gaAccountSummaries",
  inherit = gaCollection,
  public = list(
    INSERT = NULL,
    DELETE = NULL,
    print = function(...) {
      super$print(...)
      cat("  $flatSummary : < list >\n")
    }
  ),
  active = list(
    flatSummary = function() {
      ldply(seq_along(self$entities), function(entity_i){
        data.frame(
          self$summary[entity_i, c('id', 'name')],
          self$entities[[entity_i]]$summary,
          row.names = NULL
        )
      }, .id = NULL)
    }
  ),
  private = list(
    entity_class = gaAccountSummary,
    field_corrections = gaAccountSummary$private_methods$field_corrections
  )
)

#' GTM Account Summaries
#'
#' Get a collection of Google Analytics account summaries.
#'
#' @param creds The Google APIs credentials to use.
#'
#' @export
GaAccountSummaries <- function(creds = get_creds()){
  gaAccountSummaries$new(creds = creds)
}

gaAccount <- R6Class(
  "gaAccount",
  inherit = gaResource,
  public = list(
    get = function() {
      if (!is.null(self$.req_path)) {
        account_fields <- subset(
          gaAccounts$new(creds = self$creds)$summary,
          subset = id == self$id
        )
        self$modify(account_fields)
      }
      self
    },
    UPDATE = NULL,
    print = function(...) {
      super$print(...)
      cat("  $properties\n")
      cat("  $users\n")
      cat("  $filters\n")
    }
  ),
  active = list(
    properties = function() {self$.child_nodes(gaProperties)},
    users = function() {
      tryCatch(
        self$.child_nodes(gaAccountUserLinks),
        error = function(e) {
          e$message
        }
      )
    },
    filters = function() {
      self$.child_nodes(gaViewFilters)
    }
  ),
  private = list(
    parent_class_name = "NULL",
    request = "accounts",
    field_corrections = function(field_list) {
      field_list <- super$field_corrections(field_list)
      mutate(
        field_list,
        permissions = lapply(permissions$effective, factor,
          levels = user_permission_levels
        )
      )
    }
  )
)

#' GA Account
#'
#' Get a GA account.
#'
#' @param id ID of the GA account to get
#' @param creds The Google APIs credentials to use.
#'
#' @export
GaAccount <- function(id = NULL, creds = get_creds()){
  gaAccount$new(id = id, creds = creds)
}

gaAccounts <- R6Class(
  "gaAccounts",
  inherit = gaCollection,
  public = list(
    INSERT = NULL,
    DELETE = NULL
  ),
  private = list(
    entity_class = gaAccount,
    field_corrections = gaAccount$private_methods$field_corrections
  )
)

#' GTM Accounts
#'
#' Get the collection of GA accounts accessible to the user with the credentials
#' supplied by \code{creds}..
#'
#' @param creds The Google APIs credentials to use.
#'
#' @export
GaAccounts <- function(creds = get_creds()){
  gaAccounts$new(creds = creds)
}

gaViewFilter <- R6Class(
  "gaViewFilter",
  inherit = gaResource,
  public = list(
    type = NA,
    details = NA,
    print = function(...) {
      super$print(...)
      cat("  $type       = ", self$type, "\n")
      cat("  $details    = <", class(self$details), ">\n")
    }
  ),
  active = list(
    api_list = function() {
      type <- self$type
      details <- as.list(self$details[[1]])
      details <- switch(as.character(self$type),
        ADVANCED = list(advancedDetails = details),
        EXCLUDE = list(excludeDetails = details),
        INCLUDE = list(includeDetails = details),
        LOWERCASE = list(lowercaseDetails = details),
        SEARCH_AND_REPLACE = list(searchAndReplaceDetails = details),
        UPPERCASE = list(uppercaseDetails = details)
      )
      c(super$api_list, list(type = type), details)
    }
  ),
  private = list(
    parent_class_name = "gaAccount",
    request = "filters",
    field_corrections = function(field_list){
      field_list <- super$field_corrections(field_list)
      detailsFunction <- function(row) {
        details <- switch(as.character(row$type),
                ADVANCED = row$advancedDetails,
                EXCLUDE = row$excludeDetails,
                INCLUDE = row$includeDetails,
                LOWERCASE = row$lowercaseDetails,
                SEARCH_AND_REPLACE = row$searchAndReplaceDetails,
                UPPERCASE = row$uppercaseDetails
        )
        as.list(details)
      }
      if(is.data.frame(field_list)) {
        details <- alply(field_list, 1, detailsFunction)
        attributes(details) <- NULL
      } else {
        details <- list(detailsFunction(field_list))
      }
      field_list$details <- details
      field_list
    }
  )
)

gaViewFilters <- R6Class(
  "gaViewFilters",
  inherit = gaCollection,
  private = list(
    entity_class = gaViewFilter,
    field_corrections = gaViewFilter$private_methods$field_corrections
  )
)

gaAccountUserLink <- R6Class(
  "gaAccountUserLink",
  inherit = gaResource,
  public = list(
    email = NA,
    local_permissions = list(
      READ_AND_ANALYZE = TRUE,
      COLLABORATE = TRUE,
      EDIT = FALSE,
      MANAGE_USERS = FALSE
    ),
    effective_permissions = list(
      READ_AND_ANALYZE = TRUE,
      COLLABORATE = TRUE,
      EDIT = FALSE,
      MANAGE_USERS = FALSE
    ),
    modify = function(field_list) {
      super$modify(field_list)
      self$local_permissions <- unlist(self$local_permissions, recursive = FALSE)
      self$effective_permissions <- unlist(self$effective_permissions, recursive = FALSE)
    },
    print = function(...) {
      super$print(...)
      cat("  $email                 = ", self$email, "\n")
      cat("  $local_permissions     = <", class(self$local_permissions), ">\n")
      cat("  $effective_permissions = <", class(self$effective_permissions), ">\n")
    }
  ),
  active = list(
    api_list = function() {
      list(
        entity = list(
          accountRef = list(
            id  = self$parent$id
          )
        ),
        userRef = list(
          email = self$email
        ),
        permissions = list(
          local = unlist(unsplit_permissions(list(self$local_permissions)))
        )
      )
    }
  ),
  private = list(
    parent_class_name = "gaAccount",
    request = "entityUserLinks",
    scope = ga_scopes['manage_users'],
    field_corrections = function(field_list) {
      field_list <- super$field_corrections(field_list)
      field_list$email <- field_list$userRef$email
      field_list <- mutate(
        field_list,
        local_permissions = split_permissions(permissions$local),
        effective_permissions = split_permissions(permissions$effective)
      )
    }
  )
)

gaAccountUserLinks <- R6Class(
  "gaAccountUserLinks",
  inherit = gaCollection,
  public = list(
    INSERT = function(entity) {
      super$INSERT(entity = entity, scope = private$scope)
    },
    DELETE = function(id) {
      super$DELETE(id = id, scope = private$scope)
    }
  ),
  private = list(
    entity_class = gaAccountUserLink,
    scope = gaAccountUserLink$private_fields$scope,
    field_corrections = gaAccountUserLink$private_methods$field_corrections
  )
)

gaProperty <- R6Class(
  "gaProperty",
  inherit = gaResource,
  public = list(
    websiteUrl = NA,
    industryVertical = NA,
    defaultViewId = NA,
    print = function(...) {
      super$print(...)
      cat("  $websiteUrl       = ", self$websiteUrl, "\n")
      cat("  $industryVertical = ", self$industryVertical, "\n")
      cat("  $defaultViewId    = ", self$defaultViewId, "\n")
      cat("  $views\n")
      cat("  $defaultView\n")
      cat("  $users\n")
      cat("  $adwordsLinks\n")
      cat("  $dataSources\n")
    }
  ),
  active = list(
    api_list = function() {
      c(super$api_list, list(
        websiteUrl = self$websiteUrl,
        industryVertical = self$industryVertical,
        defaultProfileId = self$defaultViewId
      ))
    },
    views = function() {self$.child_nodes(gaViews)},
    defaultView = function() {
      self$views$entities[[self$defaultViewId]]
    },
    users = function() {
      tryCatch(
        self$.child_nodes(gaPropertyUserLinks),
        error = function(e) {
          e$message
        }
      )
    },
    adwordsLinks = function() {self$.child_nodes(gaAdwordsLinks)},
    dataSources = function() {self$.child_nodes(gaDataSources)}
  ),
  private = list(
    parent_class_name = "gaAccount",
    request = "webproperties",
    field_corrections = function(field_list) {
      if (is.data.frame(field_list)) {
        field_list <- super$field_corrections(field_list)
        field_list <- subset(field_list, select = c(-accountId, -internalWebPropertyId))
        names(field_list)[names(field_list) == "defaultProfileId"] <- "defaultViewId"
      }
      field_list
    }
  )
)

gaProperties <- R6Class(
  "gaProperties",
  inherit = gaCollection,
  public = list(
    DELETE = NULL
  ),
  private = list(
    entity_class = gaProperty,
    field_corrections = gaProperty$private_methods$field_corrections
  )
)

gaPropertyUserLink <- R6Class(
  "gaPropertyUserLink",
  inherit = gaResource,
  # properties and api_list active property to be implemented
  private = list(
    parent_class_name = "gaProperty",
    request = "entityUserLinks",
    scope = ga_scopes['manage_users']
  )
)

gaPropertyUserLinks <- R6Class(
  "gaPropertyUserLinks",
  inherit = gaCollection,
  public = list(
    INSERT = function(entity) {
      super$INSERT(entity = entity, scope = private$scope)
    },
    DELETE = function(id) {
      super$DELETE(id = id, scope = private$scope)
    }
  ),
  private = list(
    entity_class = gaPropertyUserLink,
    scope = gaPropertyUserLink$private_fields$scope
  )
)

gaAdwordsLink <- R6Class(
  "gaAdwordsLink",
  inherit = gaResource,
  # properties and api_list active property to be completely implemented - partially done.
  public = list(
    adWordsAccounts = NA,
    print = function(...) {
      super$print(...)
      cat("  $adWordsAccounts = ", self$adWordsAccounts, "\n")
    }
  ),
  active = list(
    api_list = function() {
      c(super$api_list, list(
        adWordsAccounts = self$adWordsAccounts
      ))
    }
  ),
  private = list(
    parent_class_name = "gaProperty",
    request = "entityAdWordsLinks"
  )
)

gaAdwordsLinks <- R6Class(
  "gaAdwordsLinks",
  inherit = gaCollection,
  private = list(
    entity_class = gaAdwordsLink
  )
)

gaCustomDimension <- R6Class(
  "gaCustomDimension",
  inherit = gaResource,
  public = list(
    index = NA,
    scope = NA,
    active = NA,
    print = function(...) {
      super$print(...)
      cat("  $index  = ", self$index, "\n")
      cat("  $scope  = ", self$scope, "\n")
      cat("  $active = ", self$active, "\n")
    }
  ),
  active = list(
    api_list = function() {
      c(super$api_list, list(
        index = self$index,
        scope = self$scope,
        active = self$active
      ))
    }
  ),
  private = list(
    parent_class_name = "gaProperty",
    request = "customDimensions"
  )
)

gaCustomDimensions <- R6Class(
  "gaCustomDimensions",
  inherit = gaCollection,
  public = list(
    DELETE = NULL
  ),
  private = list(
    entity_class = gaCustomDimension
  )
)

gaCustomMetric <- R6Class(
  "gaCustomMetric",
  inherit = gaResource,
  public = list(
    index = NA,
    scope = NA,
    active = NA,
    type = NA,
    min_value = NA,
    max_value = NA,
    print = function(...) {
      super$print(...)
      cat("  $index     = ", self$index, "\n")
      cat("  $scope     = ", self$scope, "\n")
      cat("  $active    = ", self$active, "\n")
      cat("  $type      = ", self$type, "\n")
      cat("  $min_value = ", self$min_value, "\n")
      cat("  $max_value = ", self$max_value, "\n")
    }
  ),
  active = list(
    api_list = function() {
      c(super$api_list, list(
        index = self$index,
        scope = self$scope,
        active = self$active,
        type = self$type,
        min_value = self$min_value,
        max_value = self$max_value
      ))
    }
  ),
  private = list(
    parent_class_name = "gaProperty",
    request = "customMetrics"
  )
)

gaCustomMetrics <- R6Class(
  "gaCustomMetrics",
  inherit = gaCollection,
  public = list(
    DELETE = NULL
  ),
  private = list(
    entity_class = gaCustomMetric
  )
)

gaDataSource <- R6Class(
  "gaDataSource",
  inherit = gaResource,
  public = list(
    description = NA,
    type = NA,
    importBehavior = NA,
    viewsLinked = NA,
    UPDATE = NULL,
    print = function(...) {
      super$print(...)
      cat("  $description    = ", self$description, "\n")
      cat("  $type           = ", self$type, "\n")
      cat("  $importBehavior = ", self$importBehavior, "\n")
      cat("  $viewsLinked    = ", class(self$viewsLinked), "\n")
      cat("  $uploads\n")
    }
  ),
  active = list(
    uploads = function(){self$.child_nodes(gaUploads)},
    api_list = function(){
      c(super$api_list, list(
        description = self$description,
        type = self$type,
        importBehavior = self$importBehavior,
        profilesLinked = self$viewsLinked
      ))
    }
  ),
  private = list(
    parent_class_name = "gaProperty",
    request = "customDataSources"
  )
)

gaDataSources <- R6Class(
  "gaDataSources",
  inherit = gaCollection,
  public = list(
    INSERT = NULL,
    DELETE = NULL
  ),
  private = list(
    entity_class = gaDataSource
  )
)

gaUpload <- R6Class(
  "gaUpload",
  inherit = gaResource,
  public = list(
    status = NA,
    errors = NA,
    UPDATE = NULL,
    print = function(...) {
      super$print(...)
      cat("  $status    = ", self$status, "\n")
      cat("  $errors    = ", self$errors, "\n")
    }
  ),
  private = list(
    parent_class_name = "gaDataSource",
    request = "uploads"
  )
)

gaUploads <- R6Class(
  "gaUploads",
  inherit = gaCollection,
  # INSERT and DELETE methods particular for uploads to be implemented
  private = list(
    entity_class = gaUpload
  )
)

gaView <- R6Class(
  "gaView",
  inherit = gaResource,
  public = list(
    type = NA,
    currency = NA,
    timezone = NA,
    websiteUrl = NA,
    defaultPage = NA,
    excludeQueryParameters = NA,
    siteSearchQueryParameters = NA,
    stripSiteSearchQueryParameters = NA,
    siteSearchCategoryParameters = NA,
    stripSiteSearchCategoryParameters = NA,
    eCommerceTracking = NA,
    enhancedECommerceTracking = NA,
    botFilteringEnabled = NA,
    print = function(...) {
      super$print(...)
      cat("  $type                           = ", self$type, "\n")
      cat("  $currency                       = ", self$currency, "\n")
      cat("  $timezone                       = ", self$timezone, "\n")
      cat("  $websiteUrl                     = ", self$websiteUrl, "\n")
      cat("  $defaultPage                    = ", self$defaultPage, "\n")
      cat("  $excludeQueryParameters         = ", self$excludeQueryParameters, "\n")
      cat("  $siteSearchQueryParameters      = ", self$siteSearchQueryParameters, "\n")
      cat("  $stripSiteSearchQueryParameters = ", self$stripSiteSearchQueryParameters, "\n")
      cat("  $eCommerceTracking              = ", self$eCommerceTracking, "\n")
      cat("  $enhancedECommerceTracking      = ", self$enhancedECommerceTracking, "\n")
      cat("  $botFilteringEnabled            = ", self$botFilteringEnabled, "\n")
      cat("  $goals\n")
      cat("  $experiments\n")
      cat("  $unsampledReports\n")
      cat("  $users\n")
      cat("  $viewFilterLinks\n")
    }
  ),
  active = list(
    goals = function() {self$.child_nodes(gaGoals)},
    experiments = function() {self$.child_nodes(gaExperiments)},
    unsampledReports = function() {self$.child_nodes(gaUnsampledReports)},
    users = function() {
      tryCatch(
        self$.child_nodes(gaViewUserLinks),
        error = function(e) {
          e$message
        }
      )
    },
    viewFilterLinks = function() {self$.child_nodes(gaViewFilterLinks)},
    api_list = function() {
      c(super$api_list, list(
        type = self$type,
        currency = self$currency,
        timezone = self$timezone,
        websiteUrl = self$websiteUrl,
        defaultPage = self$defaultPage,
        excludeQueryParameters = self$excludeQueryParameters,
        siteSearchQueryParameters = self$siteSearchQueryParameters,
        stripSiteSearchQueryParameters = self$stripSiteSearchQueryParameters,
        siteSearchCategoryParameters = self$siteSearchCategoryParameters,
        stripSiteSearchCategoryParameters = self$stripSiteSearchCategoryParameters,
        eCommerceTracking = self$eCommerceTracking,
        enhancedECommerceTracking = self$enhancedECommerceTracking,
        botFilteringEnabled = self$botFilteringEnabled
      ))
    }
  ),
  private = list(
    parent_class_name = "gaProperty",
    request = "profiles",
    field_corrections = function(field_list) {
      field_list <- super$field_corrections(field_list)
      field_list$type = factor(field_list$type, levels = view_type_levels)
      field_list$currency = factor(field_list$currency, levels = currency_levels)
      field_list$stripSiteSearchQueryParameters = identical(field_list$stripSiteSearchQueryParameters, TRUE)
      field_list$stripSiteSearchCategoryParameters = identical(field_list$stripSiteSearchCategoryParameters, TRUE)
      field_list
    }
  )
)

gaViews <- R6Class(
  "gaViews",
  inherit = gaCollection,
  private = list(
    entity_class = gaView,
    field_corrections = gaView$private_methods$field_corrections
  )
)

gaGoal <- R6Class(
  "gaGoal",
  inherit = gaResource,
  public = list(
    type = NA,
    value = NA,
    active = NA,
    details = NA,
    print = function(...) {
      super$print(...)
      cat("  $type    = ", self$type, "\n")
      cat("  $value   = ", self$value, "\n")
      cat("  $active  = ", self$active, "\n")
      cat("  $details = <", class(self$details), ">\n")
    }
  ),
  active = list(
    api_list = function(){
      x <- c(super$api_list, list(
        type = self$type,
        value = self$value,
        active = self$active
      ))
      x[[switch(
        self$type,
        URL_DESTINATION = "urlDestinationDetails",
        VISIT_TIME_ON_SITE = "visitTimeOnSiteDetails",
        VISIT_NUM_PAGES = "visitNumPagesDetails",
        EVENT = "eventDetails"
      )]] <- self$details
      x
    }
  ),
  private = list(
    field_corrections = function(field_list) {
      field_list$details <- switch(
        field_list$type,
        URL_DESTINATION = field_list$urlDestinationDetails,
        VISIT_TIME_ON_SITE = field_list$visitTimeOnSiteDetails,
        VISIT_NUM_PAGES = field_list$visitNumPagesDetails,
        EVENT = field_list$eventDetails
      )
      field_list
    },
    parent_class_name = "gaView",
    request = "goals"
  )
)

gaGoals <- R6Class(
  "gaGoals",
  inherit = gaCollection,
  private = list(
    entity_class = gaGoal
  )
)

gaExperiment <- R6Class(
  "gaExperiment",
  inherit = gaResource,
  # properties and api_list active property to be completely implemented - partially done.
  public = list(
    description = NA,
    objectiveMetric = NA,
    optimizationType = NA,
    status = NA,
    winnerFound = NA,
    startTime = NA,
    endTime = NA,
    reasonExperimentEnded = NA,
    rewriteVariationUrlsAsOriginal = NA,
    winnerConfidenceLevel = NA,
    minimumExperimentLengthInDays = NA,
    trafficCoverage = NA,
    equalWeighting = NA,
    servingFramework = NA,
    variations = NA,
    print = function(...) {
      super$print(...)
      cat("  $description                    = ", self$description, "\n")
      cat("  $objectiveMetric                = ", self$objectiveMetric, "\n")
      cat("  $optimizationType               = ", self$optimizationType, "\n")
      cat("  $status                         = ", self$status, "\n")
      cat("  $winnerFound                    = ", self$winnerFound, "\n")
      cat("  $startTime                      = ", self$startTime, "\n")
      cat("  $endTime                        = ", self$endTime, "\n")
      cat("  $reasonExperimentEnded          = ", self$reasonExperimentEnded, "\n")
      cat("  $rewriteVariationUrlsAsOriginal = ", self$rewriteVariationUrlsAsOriginal, "\n")
      cat("  $winnerConfidenceLevel          = ", self$winnerConfidenceLevel, "\n")
      cat("  $minimumExperimentLengthInDays  = ", self$minimumExperimentLengthInDays, "\n")
      cat("  $trafficCoverage                = ", self$trafficCoverage, "\n")
      cat("  $equalWeighting                 = ", self$equalWeighting, "\n")
      cat("  $servingFramework               = ", self$servingFramework, "\n")
      cat("  $variations                     = ", self$variations, "\n")
    }
  ),
  active = list(
    api_list = function(){
      c(super$api_list, list(
        description = self$description,
        objectiveMetric = self$objectiveMetric,
        optimizationType = self$optimizationType,
        status = self$status,
        winnerFound = self$winnerFound,
        startTime = self$startTime,
        endTime = self$endTime,
        reasonExperimentEnded = self$reasonExperimentEnded,
        rewriteVariationUrlsAsOriginal = self$rewriteVariationUrlsAsOriginal,
        winnerConfidenceLevel = self$winnerConfidenceLevel,
        minimumExperimentLengthInDays = self$minimumExperimentLengthInDays,
        trafficCoverage = self$trafficCoverage,
        equalWeighting = self$equalWeighting,
        servingFramework = self$servingFramework,
        variations = self$variations
      ))
    }
  ),
  private = list(
    parent_class_name = "gaView",
    request = "experiments"
  )
)

gaExperiments <- R6Class(
  "gaExperiments",
  inherit = gaCollection,
  private = list(
    entity_class = gaExperiment
  )
)

gaUnsampledReport <- R6Class(
  "gaUnsampledReport",
  inherit = gaResource,
  # properties and api_list active property to be completely implemented - partially done.
  public = list(
    title = NA,
    startDate = NA,
    endDate = NA,
    metrics = NA,
    dimensions = NA,
    filters = NA,
    segment = NA,
    status = NA,
    downloadType = NA,
    driveDownloadDetails = NA,
    cloudStorageDownloadDetails = NA,
    UPDATE = NULL,
    print = function(...) {
      super$print(...)
      cat("  $title                       = ", self$title, "\n")
      cat("  $startDate                   = ", self$startDate, "\n")
      cat("  $endDate                     = ", self$endDate, "\n")
      cat("  $metrics                     = ", self$metrics, "\n")
      cat("  $dimensions                  = ", self$dimensions, "\n")
      cat("  $filters                     = ", self$filters, "\n")
      cat("  $segment                     = ", self$segment, "\n")
      cat("  $status                      = ", self$status, "\n")
      cat("  $downloadType                = ", self$downloadType, "\n")
      cat("  $driveDownloadDetails        = ", self$driveDownloadDetails, "\n")
      cat("  $cloudStorageDownloadDetails = ", self$cloudStorageDownloadDetails, "\n")
    }
  ),
  private = list(
    parent_class_name = "gaView",
    request = "unsampledReports"
  )
)

gaUnsampledReports <- R6Class(
  "gaUnsampledReports",
  inherit = gaCollection,
  private = list(
    entity_class = gaUnsampledReport
  )
)

gaViewUserLink <- R6Class(
  "gaViewUserLink",
  inherit = gaResource,
  # properties and api_list active property to be implemented
  private = list(
    parent_class_name = "gaView",
    request = "entityUserLinks",
    scope = ga_scopes['manage_users']
  )
)

gaViewUserLinks <- R6Class(
  "gaViewUserLinks",
  inherit = gaCollection,
  public = list(
    INSERT = function(entity) {
      super$INSERT(entity = entity, scope = private$scope)
    },
    DELETE = function(id) {
      super$DELETE(id = id, scope = private$scope)
    }
  ),
  private = list(
    entity_class = gaViewUserLink,
    scope = gaViewUserLink$private_fields$scope
  )
)

gaViewFilterLink <- R6Class(
  "gaViewFilterLink",
  inherit = gaResource,
  # properties and api_list active property to be implemented
  private = list(
    parent_class_name = "gaView",
    request = "profileFilterLinks"
  )
)

gaViewFilterLinks <- R6Class(
  "gaViewFilterLinks",
  inherit = gaCollection,
  private = list(
    entity_class = gaViewFilterLink
  )
)

#' `gaGoal` class
#'
#' An R6 class representing a defined Google Analytics goal.
#'
#' @name gaGoal-class
#' @rdname gaGoal-class
#' @keywords internal
#' @exportClass gaGoal
setOldClass(c("gaGoal", "R6"))

#' `gaCustomDimension` class
#'
#' An R6 class representing a defined Google Analytics custom dimension.
#'
#' @name gaCustomDimension-class
#' @rdname gaCustomDimension-class
#' @keywords internal
#' @exportClass gaCustomDimension
setOldClass(c("gaCustomDimension", "R6"))

#' `gaCustomMetric` class
#'
#' An R6 class representing a defined Google Analytics custom metric.
#'
#' @name gaCustomMetric-class
#' @rdname gaCustomMetric-class
#' @keywords internal
#' @exportClass gaCustomMetric
setOldClass(c("gaCustomMetric", "R6"))

#' `gaUserSegment` class
#'
#' An R6 class representing a default or custom segment available with the
#' credentials provided.
#'
#' @name gaUserSegment-class
#' @rdname gaUserSegment-class
#' @keywords internal
#' @exportClass gaUserSegment
setOldClass(c("gaUserSegment", "R6"))

#' `gaAccount` class
#'
#' An R6 class representing a Google Analytics account.
#'
#' @name gaAccount-class
#' @rdname gaAccount-class
#' @keywords internal
#' @exportClass gaAccount
setOldClass(c("gaAccount", "R6"))

#' `gaProperty` class
#'
#' An R6 class representing a Google Analytics property.
#'
#' @name gaProperty-class
#' @rdname gaProperty-class
#' @keywords internal
#' @exportClass gaProperty
setOldClass(c("gaProperty", "R6"))

#' `gaView` class
#'
#' An R6 class representing a Google Analytics reporting view.
#'
#' @name gaView-class
#' @rdname gaView-class
#' @keywords internal
#' @exportClass gaView
setOldClass(c("gaView", "R6"))

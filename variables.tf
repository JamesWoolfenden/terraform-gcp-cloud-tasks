variable "name" {
  type        = string
  description = "Name of the Cloud Tasks queue"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,100}$", var.name))
    error_message = "var.name must be 1-100 letters, numbers or hyphens"
  }
}

variable "location" {
  type        = string
  description = "Region the queue is created in"
  default     = "europe-west2"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "var.location must be a non-empty string"
  }
}

variable "invoker_service_account" {
  type        = string
  description = "ID (projects/PROJECT/serviceAccounts/EMAIL) of the dedicated service account whose OIDC token is attached to every dispatched task"

  validation {
    condition     = can(regex("^projects/[^/]+/serviceAccounts/[^/@]+@[^/]+$", var.invoker_service_account))
    error_message = "var.invoker_service_account must be a service account id of the form projects/PROJECT/serviceAccounts/EMAIL"
  }

  validation {
    condition     = !can(regex("(-compute@developer|@appspot)\\.gserviceaccount\\.com$", var.invoker_service_account))
    error_message = "var.invoker_service_account must not be a default GCP service account (Compute Engine or App Engine)"
  }
}

variable "oidc_audience" {
  type        = string
  description = "Audience for the OIDC token. Null uses the task's target URI"
  default     = null

  validation {
    condition     = var.oidc_audience == null || can(regex("^https://", var.oidc_audience))
    error_message = "var.oidc_audience must be null or an https:// URL"
  }
}

variable "http_method" {
  type        = string
  description = "HTTP method used when dispatching tasks"
  default     = "POST"

  validation {
    condition     = contains(["POST", "GET", "HEAD", "PUT", "DELETE", "PATCH", "OPTIONS"], var.http_method)
    error_message = "var.http_method must be one of POST, GET, HEAD, PUT, DELETE, PATCH or OPTIONS"
  }
}

variable "uri_override_host" {
  type        = string
  description = "Host every task is forced to (with scheme HTTPS). Required unless var.grant_enqueuers_act_as is true, because the queue attaches the invoker SA's OIDC token to every task; null leaves the task's own URI untouched"
  default     = null

  validation {
    condition     = var.uri_override_host == null || can(regex("^[a-z0-9.-]+$", var.uri_override_host))
    error_message = "var.uri_override_host must be null or a bare hostname (no scheme or path)"
  }
}

variable "max_dispatches_per_second" {
  type        = number
  description = "Maximum rate at which tasks are dispatched from the queue"
  default     = 10

  validation {
    condition     = var.max_dispatches_per_second > 0 && var.max_dispatches_per_second <= 500
    error_message = "var.max_dispatches_per_second must be greater than 0 and at most 500"
  }
}

variable "max_concurrent_dispatches" {
  type        = number
  description = "Maximum number of concurrent tasks dispatched from the queue"
  default     = 10

  validation {
    condition     = var.max_concurrent_dispatches >= 1 && var.max_concurrent_dispatches <= 5000
    error_message = "var.max_concurrent_dispatches must be between 1 and 5000"
  }
}

variable "retry_config" {
  type = object({
    max_attempts       = optional(number, 5)
    max_retry_duration = optional(string, "3600s")
    min_backoff        = optional(string, "1s")
    max_backoff        = optional(string, "300s")
    max_doublings      = optional(number, 5)
  })
  description = "Retry behaviour for failed tasks. max_attempts is bounded so a poison task cannot retry forever"
  default     = {}

  validation {
    condition     = var.retry_config.max_attempts >= 1 && var.retry_config.max_attempts <= 100
    error_message = "var.retry_config.max_attempts must be between 1 and 100 (-1/unlimited is not allowed)"
  }

  validation {
    condition     = alltrue([for d in [var.retry_config.max_retry_duration, var.retry_config.min_backoff, var.retry_config.max_backoff] : can(regex("^[0-9]+(\\.[0-9]+)?s$", d))])
    error_message = "var.retry_config durations must be strings like \"10s\""
  }

  validation {
    condition     = var.retry_config.max_doublings >= 0
    error_message = "var.retry_config.max_doublings must be zero or greater"
  }
}

variable "logging_sampling_ratio" {
  type        = number
  description = "Fraction of task operations written to Cloud Logging (greater than 0, up to 1.0)"
  default     = 1.0

  validation {
    condition     = var.logging_sampling_ratio > 0 && var.logging_sampling_ratio <= 1
    error_message = "var.logging_sampling_ratio must be greater than 0 and at most 1.0 — 0 disables logging"
  }
}

variable "enqueuers" {
  type        = list(string)
  description = "IAM members granted roles/cloudtasks.enqueuer on the queue"
  default     = []

  validation {
    condition     = alltrue([for m in var.enqueuers : !contains(["allUsers", "allAuthenticatedUsers"], m)])
    error_message = "var.enqueuers must not contain allUsers or allAuthenticatedUsers"
  }

  validation {
    condition     = alltrue([for m in var.enqueuers : can(regex("^(user|serviceAccount|group|domain|principal|principalSet):.+", m))])
    error_message = "var.enqueuers entries must be IAM member strings such as serviceAccount:EMAIL"
  }
}

variable "grant_service_agent_oidc_minting" {
  type        = bool
  description = "Grant the Cloud Tasks service agent roles/iam.serviceAccountTokenCreator on the invoker SA so it can mint OIDC tokens"
  default     = true

  validation {
    condition     = var.grant_service_agent_oidc_minting != null
    error_message = "var.grant_service_agent_oidc_minting must not be null"
  }
}

variable "grant_enqueuers_act_as" {
  type        = bool
  description = "Grant each enqueuer roles/iam.serviceAccountUser on the invoker SA, needed when tasks set their own OIDC token"
  default     = false

  validation {
    condition     = var.grant_enqueuers_act_as != null
    error_message = "var.grant_enqueuers_act_as must not be null"
  }
}

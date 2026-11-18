resource "google_cloud_tasks_queue" "main" {
  name     = var.name
  location = var.location

  rate_limits {
    max_dispatches_per_second = var.max_dispatches_per_second
    max_concurrent_dispatches = var.max_concurrent_dispatches
  }

  retry_config {
    max_attempts       = var.retry_config.max_attempts
    max_retry_duration = var.retry_config.max_retry_duration
    min_backoff        = var.retry_config.min_backoff
    max_backoff        = var.retry_config.max_backoff
    max_doublings      = var.retry_config.max_doublings
  }

  stackdriver_logging_config {
    sampling_ratio = var.logging_sampling_ratio
  }

  # Queue-level HTTP target: every task dispatched from this queue carries an
  # OIDC token for the dedicated invoker service account, so the backend
  # (Cloud Run, Cloud Functions, ...) can require authentication.
  http_target {
    http_method = var.http_method

    oidc_token {
      service_account_email = local.invoker_service_account_email
      audience              = var.oidc_audience
    }

    dynamic "uri_override" {
      for_each = var.uri_override_host == null ? [] : [var.uri_override_host]
      content {
        scheme                    = "HTTPS"
        host                      = uri_override.value
        uri_override_enforce_mode = "ALWAYS"
      }
    }
  }

  depends_on = [google_service_account_iam_member.service_agent_token_creator]
}

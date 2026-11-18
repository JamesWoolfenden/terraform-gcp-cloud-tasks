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

  lifecycle {
    # Enqueuers need no actAs on the invoker SA for a queue-level token, so
    # without a pinned host they could send invoker-authenticated requests to
    # any URL. Allow that only when enqueuers are explicitly trusted with actAs.
    precondition {
      condition     = var.uri_override_host != null || var.grant_enqueuers_act_as
      error_message = "var.uri_override_host must be set (pinning every task to that host) unless var.grant_enqueuers_act_as is true: the queue attaches the invoker SA's OIDC token to every task, so an unpinned queue lets any enqueuer call any backend the invoker SA can reach"
    }
  }
}

# The Cloud Tasks service agent mints OIDC tokens for the invoker SA when it
# dispatches a task. Granted on the invoker SA only (not project-wide).
resource "google_service_account_iam_member" "service_agent_token_creator" {
  count              = var.grant_service_agent_oidc_minting ? 1 : 0
  service_account_id = var.invoker_service_account
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = local.cloudtasks_service_agent
}

# Enqueuers that create tasks carrying their own OIDC token for the invoker SA
# need iam.serviceAccounts.actAs on it. Off by default; scoped to the invoker
# SA only.
resource "google_service_account_iam_member" "enqueuers_act_as" {
  for_each           = var.grant_enqueuers_act_as ? toset(var.enqueuers) : toset([])
  service_account_id = var.invoker_service_account
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

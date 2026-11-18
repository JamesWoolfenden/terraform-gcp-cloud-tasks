locals {
  # The Cloud Tasks Service Agent — the Google-managed identity that dispatches
  # tasks and mints the OIDC token for the invoker service account on each
  # HTTP request.
  cloudtasks_service_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudtasks.iam.gserviceaccount.com"

  # var.invoker_service_account is a google_service_account id
  # ("projects/P/serviceAccounts/EMAIL"); the OIDC token needs the bare email.
  invoker_service_account_email = element(split("/", var.invoker_service_account), 3)
}

# holden:ignore:HLD_TF_026 — examples intentionally use ../../ to reference the local module root
module "cloud_tasks" {
  source                  = "../../"
  name                    = "example-queue"
  location                = "europe-west2"
  invoker_service_account = google_service_account.invoker.id
  uri_override_host       = "example-service-abc123-nw.a.run.app"
  oidc_audience           = "https://example-service-abc123-nw.a.run.app"
  enqueuers               = ["serviceAccount:${google_service_account.producer.email}"]
}

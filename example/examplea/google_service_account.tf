resource "google_service_account" "invoker" {
  account_id   = "tasks-invoker"
  display_name = "Dedicated SA whose OIDC token Cloud Tasks attaches to dispatched tasks"
}

resource "google_service_account" "producer" {
  account_id   = "tasks-producer"
  display_name = "Workload that enqueues tasks"
}

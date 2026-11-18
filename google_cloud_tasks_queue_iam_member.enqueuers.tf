resource "google_cloud_tasks_queue_iam_member" "enqueuers" {
  for_each = toset(var.enqueuers)
  name     = google_cloud_tasks_queue.main.name
  location = var.location
  role     = "roles/cloudtasks.enqueuer"
  member   = each.value
}

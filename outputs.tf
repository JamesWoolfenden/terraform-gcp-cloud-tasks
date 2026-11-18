output "id" {
  value       = google_cloud_tasks_queue.main.id
  description = "ID of the Cloud Tasks queue"
}

output "name" {
  value       = google_cloud_tasks_queue.main.name
  description = "Name of the Cloud Tasks queue"
}

output "service_agent" {
  value       = local.cloudtasks_service_agent
  description = "IAM member string of the Cloud Tasks service agent for this project"
}

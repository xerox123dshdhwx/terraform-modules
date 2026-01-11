output "repo_url" {
  value = "https://gitlab.com/${var.gitlab_group}/${var.app_name}.git"
}

output "repo_name" {
  value = var.app_name
}
output "repo_url" {
  value = gitlab_project.app_repo.http_url_to_repo
}

output "repo_name" {
  value = gitlab_project.app_repo.name
}
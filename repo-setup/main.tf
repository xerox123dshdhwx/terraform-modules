terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 16.0"
    }
  }
}

# Get the group ID from the group path
data "gitlab_group" "target" {
  full_path = var.gitlab_group
}

# Create GitLab project inside the group
resource "gitlab_project" "app_repo" {
  name             = var.app_name
  description      = "Auto-generated Vite.js app"
  visibility_level = "private"
  namespace_id     = data.gitlab_group.target.id
}

# Setup project and push to repo
resource "null_resource" "setup_project" {
  depends_on = [gitlab_project.app_repo]

  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/setup.sh '${var.app_name}' '${var.gitlab_token}' '${var.gitlab_group}' '${var.skeleton_repo_url}' '${var.extra_dependencies}' '${var.extra_dev_dependencies}' '${var.skeleton_folders}' '${var.skeleton_files}' '${var.git_user_email}' '${var.git_user_name}' 2>&1"
  }

  triggers = {
    project_id = gitlab_project.app_repo.id
  }
}
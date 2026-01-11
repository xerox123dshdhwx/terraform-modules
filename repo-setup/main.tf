terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 16.0"
    }
  }
}

data "gitlab_group" "target" {
  full_path = var.gitlab_group
}

data "external" "project_check" {
  program = ["sh", "-c", <<-EOF
    PROJECT_PATH=$(echo "${var.gitlab_group}/${var.app_name}" | sed 's/\//%2F/g')
    RESPONSE=$(curl -s --header "PRIVATE-TOKEN: ${var.gitlab_token}" \
      "https://gitlab.com/api/v4/projects/$PROJECT_PATH")
    PROJECT_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
    if [ -n "$PROJECT_ID" ]; then
      echo "{\"exists\": \"true\", \"id\": \"$PROJECT_ID\"}"
    else
      echo "{\"exists\": \"false\", \"id\": \"0\"}"
    fi
  EOF
  ]
}

locals {
  project_exists = data.external.project_check.result.exists == "true"
}

resource "gitlab_project" "app_repo" {
  count            = local.project_exists ? 0 : 1
  name             = var.app_name
  description      = "Auto-generated Vite.js app"
  visibility_level = "private"
  namespace_id     = data.gitlab_group.target.id
}

resource "null_resource" "setup_project" {
  depends_on = [gitlab_project.app_repo]

  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/setup.sh '${var.app_name}' '${var.gitlab_token}' '${var.gitlab_group}' '${var.skeleton_repo_url}' '${var.extra_dependencies}' '${var.extra_dev_dependencies}' '${var.skeleton_folders}' '${var.skeleton_files}' '${var.git_user_email}' '${var.git_user_name}' '${local.project_exists}' 2>&1"
  }

  triggers = {
    project_id = local.project_exists ? data.external.project_check.result.id : gitlab_project.app_repo[0].id
  }
}
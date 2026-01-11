variable "extra_dependencies" {
  description = "Additional npm packages to install (space-separated)"
  type        = string
  default     = ""
}

variable "extra_dev_dependencies" {
  description = "Additional npm dev packages to install (space-separated)"
  type        = string
  default     = ""
}

# Required
variable "app_name" {
  description = "Name of the project/repo"
  type        = string
}

variable "gitlab_token" {
  description = "GitLab PAT for authentication"
  type        = string
  sensitive   = true
}

variable "gitlab_group" {
  description = "GitLab username or organization"
  type        = string
}

# Optional - Skeleton
variable "skeleton_repo_url" {
  description = "Git URL of skeleton repository"
  type        = string
  default     = ""
}

variable "skeleton_folders" {
  description = "Folders to copy from skeleton (space-separated)"
  type        = string
  default     = "src public"
}

variable "skeleton_files" {
  description = "Files to copy from skeleton (space-separated)"
  type        = string
  default     = "tsconfig.json tsconfig.app.json tsconfig.node.json vite.config.ts"
}

# Optional - Git
variable "git_user_email" {
  description = "Git commit author email"
  type        = string
  default     = "ci@automated.com"
}

variable "git_user_name" {
  description = "Git commit author name"
  type        = string
  default     = "Automated CI"
}
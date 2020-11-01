variable "config_file_path" {
  type        = string
  description = "The path to the kube config"
}

variable "gitops_dir" {
  type        = string
  description = "The directory where the gitops configuration should be stored"
  default     = ""
}

variable "registry_namespace" {
  type        = string
  description = "The namespace in the image registry where images will be stored. This value can contain slashes."
  default     = ""
}

variable "registry_host" {
  type        = string
  description = "The host name of the image registry"
  default     = ""
}

variable "registry_url" {
  type        = string
  description = "The public url of the image registry"
  default     = ""
}

variable "registry_user" {
  type        = string
  description = "The username for the image registry"
  default     = ""
}

variable "registry_password" {
  type        = string
  description = "The password for the image registry"
  default     = ""
}

variable "cluster_type_code" {
  type        = string
  description = "The cluster_type of the cluster"
  default     = "ocp4"
}

variable "cluster_namespace" {
  type        = string
  description = "The namespace in the cluster where the configuration should be created (e.g. tools)"
}

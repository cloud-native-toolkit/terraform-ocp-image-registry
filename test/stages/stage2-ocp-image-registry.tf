module "dev_tools_ocp-image-registry" {
  source = "./module"

  config_file_path = module.dev_cluster.config_file_path
  cluster_namespace = module.dev_capture_tools_state.namespace
}

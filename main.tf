provider "helm" {
  kubernetes {
    config_path = var.config_file_path
  }
}

locals {
  tmp_dir               = "${path.cwd}/.tmp"
  gitops_dir            = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name            = "image-registry"
  chart_dir             = "${local.gitops_dir}/${local.chart_name}"
  registry_namespace    = var.registry_namespace != "" ? var.registry_namespace : "default"
  release_name          = "image-registry"
  registry_host         = var.registry_host != "" ? var.registry_host : ""
  registry_url          = var.registry_url != "" ? var.registry_url : "https://${local.registry_host}"
  global_config = {
    clusterType = var.cluster_type_code
  }
  imageregistry_config  = {
    name = "registry"
    displayName = "Image Registry"
    url = local.registry_url
    privateUrl = local.registry_host
    otherSecrets = {
      namespace = local.registry_namespace
    }
    username = var.registry_user
    password = var.registry_password
    applicationMenu = true
  }
}

resource "null_resource" "create_dirs" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.gitops_dir}"
  }
}

resource "null_resource" "setup-chart" {
  depends_on = ["null_resource.create_dirs"]

  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource "null_resource" "delete-helm-image-registry" {
  provisioner "local-exec" {
    command = "kubectl delete secret -n ${var.cluster_namespace} -l name=${local.release_name} --ignore-not-found"

    environment = {
      KUBECONFIG = var.config_file_path
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${var.cluster_namespace} registry-access --ignore-not-found"

    environment = {
      KUBECONFIG = var.config_file_path
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${var.cluster_namespace} registry-config --ignore-not-found"

    environment = {
      KUBECONFIG = var.config_file_path
    }
  }
}

resource "null_resource" "delete-consolelink" {
  count      = var.cluster_type_code == "ocp4" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink toolkit-registry --ignore-not-found"

    environment = {
      KUBECONFIG = var.config_file_path
    }
  }
}

resource "local_file" "image-registry-values" {
  depends_on = [null_resource.setup-chart]

  content  = yamlencode({
    global = local.global_config
    tool-config = local.imageregistry_config
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  provisioner "local-exec" {
    command = "cat ${local_file.image-registry-values.filename}"
  }
}

resource "helm_release" "registry_setup" {
  depends_on = [null_resource.delete-helm-image-registry, null_resource.delete-consolelink, local_file.image-registry-values]

  name              = "image-registry"
  chart             = local.chart_dir
  namespace         = var.cluster_namespace
  timeout           = 1200
  dependency_update = true
  force_update      = true
  replace           = true

  disable_openapi_validation = true
}

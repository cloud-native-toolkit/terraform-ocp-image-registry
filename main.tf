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
  release_name          = "image-registry"
  console_url_file     = "${local.tmp_dir}/console.host"
  console_url           = var.apply ? data.local_file.console_url[0].content : ""
  registry_host         = "image-registry.openshift-image-registry.svc:5000"
  registry_url          = "${local.console_url}/k8s/all-namespaces/imagestreams"
  global_config = {
    clusterType = var.cluster_type_code
  }
  imageregistry_config  = {
    name = "registry"
    displayName = "Image Registry"
    url = local.registry_url
    privateUrl = local.registry_host
    applicationMenu = true
  }
}

resource "null_resource" "create_dirs" {
  count = var.apply ? 1 : 0
  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.gitops_dir}"
  }
}

resource "null_resource" "setup-chart" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.create_dirs]

  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource "null_resource" "delete-helm-image-registry" {
  count = var.apply ? 1 : 0
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

resource "null_resource" "get_console_url" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.create_dirs]

  provisioner "local-exec" {
    command = "${path.module}/scripts/get-console-url.sh ${local.console_url_file}"

    environment = {
      KUBECONFIG = var.config_file_path
    }
  }
}

data "local_file" "console_url" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.get_console_url]

  filename = local.console_url_file
}

resource "null_resource" "print_console_url" {
  count = var.apply ? 1 : 0
  provisioner "local-exec" {
    command = "echo 'host: ${local.console_url}'"
  }
}

resource "null_resource" "delete-consolelink" {
  count      = var.cluster_type_code == "ocp4" && var.apply ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink toolkit-registry --ignore-not-found"

    environment = {
      KUBECONFIG = var.config_file_path
    }
  }
}

resource "local_file" "image-registry-values" {
  count = var.apply ? 1 : 0
  depends_on = [null_resource.setup-chart]

  content  = yamlencode({
    global = local.global_config
    tool-config = local.imageregistry_config
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  count = var.apply ? 1 : 0

  provisioner "local-exec" {
    command = "cat ${local_file.image-registry-values[0].filename}"
  }
}

resource "helm_release" "registry_setup" {
  count = var.apply ? 1 : 0
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

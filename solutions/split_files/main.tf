check "workshop_project_is_used" {
  assert {
    condition     = var.project_id == "cloud-labs-workshop-42clws"
    error_message = "The provider should be using the cloud-labs-workshop. This check is a safety measure to prevent provisioning in other projects. If you're running in your own project, edit or delete this check."
  }
}

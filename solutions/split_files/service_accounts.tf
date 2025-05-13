resource "google_service_account" "service_accounts" {
  count        = length(var.service_accounts)
  account_id   = "${var.name_prefix}-${var.service_accounts[count.index]}"
  display_name = "Workshop ${var.service_accounts[count.index]} service account"
  description  = "Service account for ${var.service_accounts[count.index]} services"
}

resource "google_project_iam_member" "project_roles" {
  count   = length(var.project_roles) * length(google_service_account.service_accounts)
  project = var.project_id
  role    = var.project_roles[floor(count.index / length(var.service_accounts))]

  member = "serviceAccount:${google_service_account.service_accounts[count.index % length(google_service_account.service_accounts)].email}"
}

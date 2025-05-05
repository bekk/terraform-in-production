# Terraform in production

## Getting started

- Verification of prerequisites (Terraform CLI, Google Cloud account setup)

### Installing prerequisites

Install Terraform CLI, and Google Cloud SDK.

#### Terraform

This will provide the `terraform` binary.

- Windows: Download from [the official installation page](https://developer.hashicorp.com/terraform/install) and follow the installation instructions.
- Windows (chocolatey): Run `choco install terraform`.
- macOS: Use Homebrew with `brew install terraform`.
- Linux: Go to the [official installation page](https://developer.hashicorp.com/terraform/install) and follow the instructions for your distribution.

#### Google Cloud SDK

This will provide the `gcloud` binary.

- Windows: Download from [the official installation page](https://cloud.google.com/sdk/docs/install#windows) and follow the installation instructions.
- Windows (chocolatey): Run `choco install gcloudsdk`.
- macOS: Use Homebrew with `brew install --cask google-cloud-sdk`.
- Linux: Go to the [official installation page](https://cloud.google.com/sdk/docs/install) and follow the instructions for your distribution.

### Login to Google Cloud

#### Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and log in with your Google account.
2. Grab the project ID of the project you will be using for the workshop. You can find it in the project dashboard or by clicking on the project name in the top navigation bar.


#### gcloud

In a terminal, run the following command to log in:

```bash
gcloud auth login
```

This will open a web browser for you to log in with your Google account. After logging in, you will be prompted to select a project. Choose the project you will be using for the workshop.

If you're not prompted to select a project, set the project with:

```bash
gcloud config set project cloud-labs-workshop-project-42clws
```

Then run:

```bash
glcoud auth application-default login
```

To verify your project, run:

```bash
gcloud config list
```

## Part 1: State management and modularization

<!--
### State Management Fundamentals (45 minutes)
- Deep dive into Terraform state structure
- Hands-on exercise: Inspecting state with `terraform state list` and `terraform state show`
- Understanding state locking and why it matters

### State Manipulation Workshop (60 minutes)
- Practical exercise: Renaming resources using `terraform state mv`
- Hands-on task: Moving resources between configurations
- Lab: Resolving common state conflicts and drift scenarios

### Remote State Migration (45 minutes)
- Setting up a Google Cloud Storage (GCS) bucket for state storage
- Hands-on exercise: Migrating local state to GCS backend
- Configuring state locking with GCS object versioning
-->

This part will focus on **Terraform state fundamentals** and **basic state manipulation**. 

### 1.1: State management fundamentals

#### Concept: What is Terraform state?

Terraform uses state to map resource configurations to real-world infrastructure. The state file (`terraform.tfstate`) is a JSON file that contains the current state of your infrastructure. It is essential for Terraform to function correctly, as it allows Terraform to track resources and their dependencies. It will not contain all resources, only the resources Terraform know about.

The state file can contain sensitive information, so it should be stored securely. Terraform 1.10 inroduced ephemerality, with the special `ephemeral` block, that solves some issues related to sensitive information. You can read more about it [in the docs](https://developer.hashicorp.com/terraform/language/resources/ephemeral).

Let's start with a simple example of a monolithic configuration. We've provided a starter configuration in `infra/main.tf` that creates a couple of networks, DNS records and service accounts.

* Create a new file `infra/terraform.auto.tfvars` with the following content:

    ```hcl
    name_prefix = "<your-unique-prefix>"
    project_id = "cloud-labs-workshop-42clws"
    ```

    Your `name_prefix` should be unique to avoid collisions with other participants. If you run the workshop in your own project, replace the `project_id` accordingly.

* Run `terraform init` and `terraform apply` in the `infra/` folder to provision the resources. Contact a workshop facilitator if you have any troubles.


The previous commands will have created a `.terraform/` directory, a `.terraform.lock.hcl` and a `terraform.tfstate` file. `.terraform.lock.hcl` is the only file that should be committed. `.terraform/` contain downloaded providers and modules.

* Open `terraform.tfstate` in your favorite text editor. You will see a JSON file with the current state of your infrastructure. The `resources` key contains a list of all resources managed by Terraform, along with their attributes and metadata.

* `terraform.tfstate` contains many attributes that are not relevant. Run `terraform state list` to see a list of all resources managed by Terraform. You will see a list of resources with their addresses, such as `google_compute_network.vpc` and `google_dns_record_set.records[2]`.

* Run `terraform state show google_compute_network.vpc` to see the details of the `google_compute_network.vpc` resource. You will see a list of all attributes and their values, including the `id`, `name`, `auto_create_subnetworks`, and `project`.

* Run `terraform show` to display the attributes of all Terraform-managed resources.

### 1.2: Basic state manipulation

#### Renaming resources in state

Terraform has two mechanisms for changing the address of a resource. `terraform state mv` and the `moved` block. The first one act on the state file directly, and the second is most commonly used when renaming resources in the configuration. 

1. Run `terraform state mv google_compute_network.vpc google_compute_network.vpc_renamed` to rename the `google_compute_network.vpc` resource to `google_compute_network.vpc_renamed`. This will update the state file, but not the configuration.

2. Run `terraform plan` to examine how Terraform wishes to fix the configuration drift between the state file and the configuration file. Note especially how this affects dependant resources, like the subnets and the DNS zone. Do not apply this configuration!

3. Let's fix the state file with a [`moved` block](https://developer.hashicorp.com/terraform/language/moved):

    ```hcl
    moved {
      from = google_compute_network.vpc_renamed
      to = google_compute_network.vpc
    }
    ```

    Examine the output of `terraform plan` again. It should show the change to the state file, but also say "Plan: 0 to add, 0 to change, 0 to destroy" since this involves no actual changes. 

4. Apply the configuration (using `terraform apply`) before continuing. Then remove the `moved` block from the configuration.

5. The `moved` blocks and `terraform state` commands also work on maps and lists of objects, such as `google_compute_subnetwork.subnets` (which has 3 resources). We'll do the same operation, but this time we'll start with the `moved` block.

    Start by changing the address of the resources from `subnets` to `subnets_renamed`, and optionally run `terraform plan` to view what happens. Then create a `moved` block that renames the addresses in the state file. Run `terraform plan` to verify that there are no changes other than the three address changes.

6. Apply the configuration before undoing the changes in the configuration file. Running `terraform plan` should show 3 added and 3 destroyed resources. Use `terraform state mv` to fix the state file, and run `terraform plan` to verify that there are no changes.


You can read more about the available [state manipulation commands](https://developer.hashicorp.com/terraform/cli/commands/state). 


### 1.3: Drift

"Drift" is when the defined state (or code) differs from the actual state of the infrastructure. This can happen for various reasons, such as manual changes made in the cloud provider's console, code changes not properly applied in an environment or changes made by other tools or scripts.

In order to handle drift, Terraform always executes a "refresh" before plan or apply operations to update the state file with real-world status. It will then reconcile the tracked resources in the state file with the actual status.

You can trigger a refresh manually with `terraform refresh` or using the `-refresh-only` flag with `terraform plan` and `terraform apply`. Refreshing the state is normally not necessary when running `terraform plan` or `terraform apply`, but can be useuful in special situations.

1. Next, go into the Google Cloud Console, and search for "VPC networks" in the top middle search bar. Click on the "VPC networks" link and find your VPC in the list. Click "Subnets" in the menu bar, and delete one of the subnets listed.

2. Let's see the effect of refreshing the state.

    1. Run `terraform plan -refresh=false`. You should not see any changes to be applied since the state file and configuration files are in sync.
    2. Run `terraform plan -refresh-only -out=plan.tfplan`. You can see from the output which resources Terraform refreshes the status of. Terraform will generate a plan to update the state file.
    3. Run `terraform apply plan.tfplan`. To apply the changes to the state file.
    4. (Optional) You can compare the state file by looking at the difference between of `terraform.tfstate` and `terraform.tfstate.backup`.
    5. Run `terraform plan -refresh=false` again. Terraform will now detect a difference between the state file and the configuration. Terraform will show the plan to change the real-world state back to the desired state decided by the configuration.

3. Run `terraform apply` and apply the configuration to get the infrastructure back to the desired state.


> [!NOTE]
> `terraform apply -refresh-only` will give the option to update the state file without generating an intermediate state file (generally, all arguments given to `terraform plan` can also be given to `terraform apply`).
>
> `terraform refresh` can be used to refresh and apply the state to the state file directly without reviewing it. This is most similar to what is actually done by `terraform plan` before generating the actual plan.


### 1.4: Moving Resources Between Files (5 minutes)
- **Key Points:**
  - Resources can be split into multiple files to improve organization.
  - When resources are moved, Terraform may lose track unless state is updated.
- **Hands-On Task:**
  - Move the `google_dns_managed_zone.private_zone` resource block into a new file (`dns.tf`).
  - Update the state with:
    ```bash
    terraform state mv google_dns_managed_zone.private_zone module.dns.google_dns_managed_zone.private_zone
    ```
  - Verify the change.

---

## 3. **Remote State Migration**
### Concept: Why Use Remote State? (5 minutes)
- **Key Points:**
  - Remote state is essential for collaboration and to avoid conflicts.
  - It ensures state is stored securely (e.g., in a GCS bucket with encryption).
- **Hands-On Task:**
  - Create a GCS bucket for remote state storage:
    ```bash
    gsutil mb -p <project_id> -l US -b on gs://<bucket_name>
    ```
  - Update the Terraform configuration to use the bucket as a backend:
    ```hcl
    terraform {
      backend "gcs" {
        bucket = "<bucket_name>"
        prefix = "terraform/state"
      }
    }
    ```
  - Run `terraform init` and migrate the state to the bucket.

### Concept: State Locking with GCS (3 minutes)
- **Key Points:**
  - State locking prevents multiple users from making changes simultaneously.
  - GCS supports locking through object versioning.
- **Documentation Link:** [GCS Remote Backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)

---

## 4. **Refactoring for Modularization**
### Concept: Why Modularize? (3 minutes)
- **Key Points:**
  - Modules improve code reuse, organization, and readability.
  - Modules make it easier to work with teams by creating smaller, focused units of code.
- **Documentation Link:** [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)

### Hands-On Task: Moving Resources into Modules (10 minutes)
- **Step 1:** Create a `network` module:
  - Create a `modules/network` directory.
  - Move the `google_compute_network` and `google_compute_subnetwork` blocks into `modules/network/main.tf`.
  - Add input variables for dynamic values (e.g., `network_name`, `subnet_cidrs`, `region`).

- **Step 2:** Refactor the root configuration:
  - Replace the original blocks with a module call:
    ```hcl
    module "network" {
      source       = "./modules/network"
      network_name = "workshop-vpc"
      subnet_cidrs = var.subnet_cidrs
      region       = var.regions
    }
    ```

- **Step 3:** Update the state:
  - Use `terraform state mv` to move the resources into the module’s namespace:
    ```bash
    terraform state mv google_compute_network.vpc module.network.google_compute_network.vpc
    terraform state mv google_compute_subnetwork.subnets[0] module.network.google_compute_subnetwork.subnets[0]
    ```

- **Step 4:** Verify with `terraform plan`.

---

By keeping the explanations brief and linking to documentation for in-depth details, participants can focus on the hands-on tasks while still having access to additional learning materials.

## Part 2: Creating Effective Modules (2 hours)

### Module Basics (45 minutes)
- Module structure and best practices
- Input/output variables and validation
- Module versioning strategies

### Refactoring Into Modules (75 minutes)
- Hands-on lab: Identifying modularization opportunities in monolithic code
- Exercise: Breaking down a configuration into logical modules
- Exercise: Moving resources into modules while preserving state

## Part 3: Optional Deep-Dive Tracks (Choose Your Own Adventure - 5 hours)

### Track A: Multi-Environment Management
- Comparing approaches:
  - Workspace-based workflows
  - Directory-based environments with multiple state files
  - Terragrunt integration
- Hands-on lab: Implementing your chosen strategy with GCP projects

### Track B: Terraform Cloud Integration
- Setting up Terraform Cloud
- Remote execution and state management
- Team workflows and permissions
- Policy as Code with Sentinel
- Integrating with GCP service accounts

### Track C: CI/CD Pipeline Integration
- Creating workflow files for Terraform
- Implementing secure credential handling for GCP
- Options:
  - GitHub Actions setup
  - Cloud Build integration
  - Pull request automation (plan on PR, apply on merge)

### Track D: Working with Collections
- Hands-on exercises with:
  - `count` vs. `for_each`
  - `for` expressions
  - `flatten` and other collection functions
- Practical GCP examples (e.g., managing multiple GKE node pools)
- Performance considerations

### Track E: Dynamic Blocks Master Class
- Use cases for dynamic blocks
- Lab: Implementing complex GCP resource configurations with dynamic blocks
- Discussion: Performance implications and maintainability trade-offs
- Best practices and anti-patterns

### Track F: Testing and Validation
- Unit testing with Terratest
- Policy validation with OPA/Conftest
- Static analysis and linting
- Implementing pre-commit hooks
- GCP-specific compliance checks

## Wrap-up and Best Practices (30 minutes)
- Discussion of real-world challenges and solutions
- Performance optimization tips
- Resource organization strategies for GCP
- Q&A and additional resources

---

This workshop is designed to be hands-on and practical, with each participant working through exercises on their Google Cloud infrastructure. The core sections focus on essential skills of state management and modularization, while the optional tracks allow participants to choose which advanced topics are most relevant to their work context with Google Cloud Platform.

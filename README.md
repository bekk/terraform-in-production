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
gcloud config set project cloud-labs-workshop-42clws
```

Then run:

```bash
gcloud auth application-default login
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

- Create a new file `infra/terraform.auto.tfvars` with the following content:

  ```hcl
  name_prefix = "<your-unique-prefix>"
  project_id = "cloud-labs-workshop-42clws"
  ```

  Your `name_prefix` should be unique to avoid collisions with other participants. If you run the workshop in your own project, replace the `project_id` accordingly.

- Run `terraform init` and `terraform apply` in the `infra/` folder to provision the resources. Contact a workshop facilitator if you have any troubles.

The previous commands will have created a `.terraform/` directory, a `.terraform.lock.hcl` and a `terraform.tfstate` file. `.terraform.lock.hcl` is the only file that should be committed. `.terraform/` contain downloaded providers and modules.

- Open `terraform.tfstate` in your favorite text editor. You will see a JSON file with the current state of your infrastructure. The `resources` key contains a list of all resources managed by Terraform, along with their attributes and metadata.

- `terraform.tfstate` contains many attributes that are not relevant. Run `terraform state list` to see a list of all resources managed by Terraform. You will see a list of resources with their addresses, such as `google_compute_network.vpc` and `google_dns_record_set.records[2]`.

- Run `terraform state show google_compute_network.vpc` to see the details of the `google_compute_network.vpc` resource. You will see a list of all attributes and their values, including the `id`, `name`, `auto_create_subnetworks`, and `project`.

- Run `terraform show` to display the attributes of all Terraform-managed resources.

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

### 1.4: Moving resources between files

Our single configuration file is quite long and unmanageable. We can split it into multiple files to improve organization. As long as we keep the resources in files within the same directory, with the same resource name, Terraform will consider them the same. Moving files to different directories will create modules. For now, we will just create a logical split of files to simplify later refactoring.

Terraform has a [style guide](https://developer.hashicorp.com/terraform/language/style), which contains a section about file names. We will follow this style guide to reorganize our code.

1. Look up the [file names section in the style guide](https://developer.hashicorp.com/terraform/language/style#file-names).

2. Move all the non-resource blocks (variables, providers, etc.) into their respective files.

3. You should now have files named `terraform.tf`, `providers.tf`, `variables.tf` and `main.tf`.

4. The the remaining resources in `main.tf` can split into files based on their function (e.g., `dns.tf`, `network.tf`, etc.), if you want to.

5. When you're done, run `terraform plan` to verify that there are no changes to the configuration.

## 3. **Remote State Migration**

#### Why Use Remote State?

By default, Terraform stores the state locally in a `terraform.tfstate` file. When using Terraform in a team it is important for everyone to be working with the same state so that operations will be applied to the same remote objects.

With remote state, Terraform writes the state data to a remote data store, which can be shared between all members of a team. Remote state can be implemented by storing state in Amazon S3, Azure Blob Storage, Google Cloud Storage and more. Terraform configures the remote storage a [`backend` block](https://developer.hashicorp.com/terraform/language/backend).

### 3.1: Create a GCS bucket for remote state storage:

- Run the following command to create a GCS bucket:

  ```bash
  gcloud storage buckets create gs://<bucket_name> --project=cloud-labs-workshop-42clws --location=europe-west1
  ```

  <bucket_name> can be any globally unique string, we recommend <your_prefix>\_state_storage<random_string>. The <random_string> should be 4-6 random lower case letters or numbers.

  - Update the Terraform configuration to use the provisioned bucket as a backend:
    ```hcl
    terraform {
      backend "gcs" {
        bucket = "<bucket_name>"
        prefix = "terraform/state"
      }
    }
    ```
  - Run `terraform init` and migrate the state to the bucket.
  - verify that the state is located in gcloud storage bucket:
    ```bash
    gcloud storage ls gs://<BUCKET_NAME>/<PREFIX>
    ```
  - If you want to view the contents of the state file run `gcloud storage cat <PATH_TO_STATE_FILE>`

#### State Locking with GCS

As long as the backend supports state locking, Terraform will lock your state for all operations that could write state. This will prevent others from acquiring the lock and potentially corrupting your state. Since GCS supports state locking, this happens automatically on all operations that could write state. This is especially important when working in a team or when automated workflows (such as CI/CD pipelines) may run Terraform simultaneously, as it ensures only one operation can modify the state at a time.

- State lock can be verified by:
  - Try changing the "google_dns_managed_zone.private_zone" resource name and run `terraform apply` but leave it on approval prompt and then, in another terminal, run `terraform plan`. You should see that the state file is locked by the `terraform apply` operation.
- **Documentation Link:** [GCS Remote Backend](https://developer.hashicorp.com/terraform/language/settings/backends/gcs)

## 4. Refactoring for modularization

Terraform [modules](https://developer.hashicorp.com/terraform/language/modules) improve code reuse, organization and readability. Modules can be used to create reusable components in a repository or create a library of reusable components shared between teams.

### 4.1. The `network` module

We'll start with a `network` module that is responsible for creating both the VPC and the subnets. We'll also have to take care to not modify the existing resources, and will use the [`moved` block](https://developer.hashicorp.com/terraform/language/moved) to avoid actual changes to the infrastructure.

Modules are defined in their own directory, and can be used by referencing the module's source. The module's source can be a local path, a Git repository or a Terraform registry. It's common to gather modules at the repository root in the `modules/` folder.

1. Create the `modules/network` directory at the repository root.

2. Create `modules/network/main.tf` and move the `google_compute_network` and `google_compute_subnetwork` resources into it.

3. We'll need to pass variable definitions to the module. Modules follow the same naming conventions Create `modules/network/variables.tf` and copy the required variables from `variables.tf` into it (`name_prefix`, `regions`, `subnet_cidrs` from `variables.tf`). Remove the variable defaults, if any.

4. Other resources need to reference the VPC id, so we'll need a output. Create `modules/network/outputs.tf` with the following content:

   ```hcl
   output "vpc_id" {
     description = "The ID of the VPC"
     value       = google_compute_network.vpc.id
   }
   ```

5. Add a `module` block to replace the previous network configuration file to call the module:

   ```hcl
   module "network" {
     source       = "../modules/network"
     name_prefix  = var.name_prefix
     regions      = var.regions
     subnet_cidrs = var.subnet_cidrs
   }
   ```

   And update `google_dns_managed_zone.private_zone` to refer to the module output `vpc_id` in the `network_url` argument:

   ```hcl
   network_url = module.network.vpc_id
   ```

6. Run `terraform init` and then `terraform plan` to verify that the changes are syntactically correct. Fix errors before continuing. Note that the plan will show changes to the infrastructure! But, can do this without changes to the infrastructure by using the `moved` block.

7. When moving between modules, the `moved` block must be in the module you moved from (in this case the root module). Add this `moved` block in the same file as the module declaration:

   ```hcl
   moved {
     from = google_compute_network.vpc
     to   = module.network.google_compute_network.vpc
   }

   moved {
     # Note: We move all three subnets in the list at once
     from = google_compute_subnetwork.subnets
     to   = module.network.google_compute_subnetwork.subnets
   }
   ```

   Run `terraform plan` again and verify that there are no changes, except moving resources.

8. Apply the moves with `terraform apply`. This will move the resources in the state file without changing the infrastructure. Run `terraform plan` and see that the moves are no longer planned actions.

9. Delete the `moved` block from the configuration file.

> [!CAUTION]
> Removing `moved` blocks in shared modules can cause breaking changes to consumers that haven't applied the move actions yet. This is not a problem here since we're the only consumer of the module. Read more [in the docs](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring#removing-moved-blocks).

The design of the `network` module can be improved, we'll get back to ways to do that in the extra tasks section later in the workshop.

### 4.2. The `dns_a_record` module

For the DNS configuration, we'll only create a module for creating a single DNS A record, leaving the DNS zone in the root module.

1. Following similar steps to creating the `network` module, create `dns_a_record` module. This module should have three `string` variable inputs `name`, `zone_name` and `ipv4_address`, and create a single `google_dns_record_set` resource.

2. We can then use a loop with the `count` meta-argument in the root module when we call the module:

   ```hcl
   module "records" {
     count        = length(var.dns_records)
     source       = "../modules/dns_a_record"
     name         = "${var.dns_records[count.index]}.${var.name_prefix}.workshop.internal."
     zone_name    = google_dns_managed_zone.private_zone.name
     ipv4_address = "10.0.0.${10 + count.index}"
   }
   ```

3. When refactoring resources that use looping this way, we need to use a moved block per resource:

   ```hcl
   moved {
     from = google_dns_record_set.records[0]
     to   = module.records[0].google_dns_record_set.record
   }

   moved {
     from = google_dns_record_set.records[1]
     to   = module.records[1].google_dns_record_set.record
   }

   moved {
     from = google_dns_record_set.records[2]
     to   = module.records[2].google_dns_record_set.record
   }
   ```

4. Verify that the only actions are to move state, and apply the changes before removing the `moved` blocks.

### 4.3. The `service_account` module

The `service_account` module is a bit different, since it creates multiple resources using loops. The logic could be greatly simplified if we designed to module to create a service account, and assign it a set of roles.

The `service_account` module should have variables `account_id`, `display_name`, `description`, `project_id` and `roles`. I.e, we want a that can replace the current looping logic with a module call similar to this:

```hcl
module "service_accounts" {
  count  = length(var.service_accounts)
  source = "../modules/service_account"

  account_id   = "${var.name_prefix}-${var.service_accounts[count.index]}"
  display_name = "<removed for brevity>"
  description  = "<removed for brevity>"
  project_id   = var.project_id
  roles        = var.project_roles
}
```

1. Create the `service_account` module in `modules/service_account` and use it. _Note:_ This refactoring is not required to complete future tasks, and feel free to skip it or come back to it later if you want to.

## Part 3: Optional Deep-Dive Tracks (Choose Your Own Adventure - 5 hours)

### Track A: Multi-Environment Management

- Comparing approaches:
  - Workspace-based workflows
  - Directory-based environments with multiple state files
  - Terragrunt integration
- Hands-on lab: Implementing your chosen strategy with GCP projects

### Track B: Terraform Cloud Integration

#### What is Terraform Cloud?

Terraform Cloud is a managed service provided by HashiCorp for running Terraform workflows in a collaborative and secure environment. It helps teams manage infrastructure as code at scale by handling Terraform execution, state storage, access control, version control integration and policy enforcement — all in the cloud. In this part we will explore how to store state in Terraform Cloud and run automatic plan on PR.

#### 1) Setting up Terraform Cloud.

Go to [Terraform Cloud](https://app.terraform.io) and create a free account. Once signed in, create an organization to store your infrastructure. HCP Terraform organizes your infrastructure resources by workspaces in an organization.

#### 2) Create a workspace with VCS workflows

A workspace in HCP Terraform contains infrastructure resources, variables, state data, and run history. HCP Terraform offers a VCS-driven workflow that automatically triggers runs based on changes to your VCS repositories. The VCS-driven workflow enables collaboration within teams by establishing your shared repositories as the source of truth for infrastructure configuration. Complete the following steps to create a workspace:

1.  After selecting an organization, click _New_ and choose _Workspace_ from the dropdown-menu.
2.  Choose a project to create the workspace in, and click _create_.
3.  Configure the backend to let Terraform Cloud manage your state:

```hcl
terraform {
 cloud {
   hostname     = "app.terraform.io"
   organization = "<your-organization-name>"
   workspaces {
     name = "<workspace-name>"
   }
 }
}
```

Initialize the state with `terraform init`.

In order to trigger HCP Terraform runs from changes to VCS, you first need to create a new repository in your personal GitHub account.

In the GitHub UI, create a new repository. Name the repository learn-terraform, then leave the rest of the options blank and click Create repository.

Copy the remote endpoint URL for your new repository.

In the directory of your source code, update the remote endpoint URL for your repository to the one you just copied. `git remote set-url origin YOUR_REMOTE`, Add your changes, commit and push to your personal repository.

To connect your workspace with your new GitHub repository, follow the steps below:

1. In your workspace, click on VCS workflow and choose an existing version control provider from the list or configure a new system. If you choose Github App,choose an organization and repository when prompted. You can choose your own private repositories by clicking on _add_another_organization_ and selecting your github account.
2. Under advanced options, set the Terraform Working Directory to _infra_ and click Create.

Terraform Cloud also needs access to Google Cloud resources to be able to run necessary changes. We therefore need to add a workspace variable called GOOGLE_CREDENTIALS containing a service account key.

1. Go to Google Cloud -> IAM & ADMIN -> Service Accounts and locate the terraform cloud service account (terraform-cloud-sa-clws@cloud-labs-workshop-42clws.iam.gserviceaccount.com)
2. Under Actions, click on Manage keys and choose create new key under the Add key dropdown
3. Head over to Terraform Cloud and under your workspace variables, add a variable named GOOGLE_CREDENTIALS with the service account key as value.

You should now be able to automate terraform plan on PR.

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

### Track G: Checks, validation and assertions

Terraform has [a type system](https://developer.hashicorp.com/terraform/language/expressions/types), covering basic funcitonality. It allows for type constraints in the configuration. Additionally, the language has support for different types of [custom conidtions](https://developer.hashicorp.com/terraform/language/expressions/custom-conditions) to validate assumptions and provide error messages.


#### G.1 Input validation

The `network` module has two `list(string)`  input variables, `regions` and `subnet_cidrs`, that are expected to be of the same length. Let's look at different ways of verifying this. First, let's get an introduction to variable validation.


1. The `subnet_cidrs` is of type `list(string)`, we would like to validate that the ranges specified are valid. We can use a `validation` block inside our `variable` declaration. This would look like this:

    ```hcl
    variable "subnet_cidrs" {
      description = "CIDR ranges for subnets"
      type        = list(string)

      validation {
        condition     = alltrue([for cidr in var.subnet_cidrs : can(cidrhost(cidr, 255))])
        error_message = "At least one of the specified subnets were too small, or one of the CIDR range was invalid. The subnets needs to contain at least 256 IP addresses (/24 or larger)."
      }
    }
    ```

    We added the `validation` block, the rest should be like before. Let's explain what's going on here:

    - The `condition` is a boolean expression that must be true for the validation to pass.
    - [`alltrue`](https://developer.hashicorp.com/terraform/language/functions/alltrue) is a function that returns true if all elements in the list are true.
    - `for` is a [for expression](https://developer.hashicorp.com/terraform/language/expressions/for) that iterates over the list of CIDR ranges and checks if each one is valid using the `cidrhost` function.
    - We can refer to the variable being validated with the same syntax as before: `var.subnet_cidrs`.
    - [The `can` function](https://developer.hashicorp.com/terraform/language/functions/can) is a special function that returns true if the expression can be evaluated without errors. I.e., if `cidrhost` returns an error due to an invalid or to small IP address range, `can` will return false.
    - If `condition` evaluates to false, the plan fails and the `error_message` will be printed.

    *Add the validation* try to provoke a validation error by specifying a smaller IP address range (e.g., a `/25`) or specifying an invalid IP address. Make sure the code works again before moving to the next step.


> [!NOTE]
> For the following steps we will write the same code in different ways, so you might want to commit (or make a copy) of your code, in order to be able to revert later. If you've already done the tasks in Track D <!-- TODO: Not written, ensure correct reference later --> you might want to revert your changes to the network module.

2. Depending on your use case, the best way might be to combine the variables into a structured type containing a list of objects with the properties `region` and `cidr` (the type definition would be `list(object({ region = string, cidr = string}))`. This would use the type system to ensure the assumptions are always correct. In Track <!-- TODO: Not written-->we do this refactoring, and will not repeat it here.

3. Terraform 1.9.0 (released June, 2024) introduced [general expressions and cross-object references in input variable validations](https://www.hashicorp.com/en/blog/terraform-1-9-enhances-input-variable-validations). This lets us refer to different variables, locals and more during validation.

    a. Add a new validation to either the `regions` or the `subnet_cidrs` variable to ensure that the two lists are of equal lengths. The condition should be  `length(var.regions) == length(var.subnet_cidrs)`.
    b. Verify that the validation fails if the number of regions and CIDRs are not the same.


4. For the purposes of this workshop, we can do a different refactoring to illustrate multiple validation blocks: Let's combine the `regions` and `subnet_cidrs` variables into a `subnets` variable with type `object({ regions = list(string), cidrs = list(string) })`. 
    a. Remove the validation from the previous step, and modify the validation from the first step to work with the new variable type. Also update the module and the calling code to work with the new variable type defintion. Make sure `terraform plan` succeeds without modifications.
    b. Add a second validation block to the `subnets` variable that verifies that the two lists have the same length. Add an appropriate error message.
    c. Verify that the validation fails if the number of regions and CIDRs are not the same.

#### G.2 Checks

[Checks](https://developer.hashicorp.com/terraform/language/checks) lets you use custom conditions that will execute on every plan or apply operation. Failing checks will therefore not, however, have any effect on Terraform's execution of operations.


1. Checks are very flexible. We can write the input validations in the previous step as assertions. Transform the validation of subnet CIDRs into a check. The general syntax of a check is:

    ```hcl
    check "check_name" {
      // Optional data block

      // At least one assertion block
      assert {
        condtion      = 1 == 1 // condition boolean expression
        error_message = "error message"
      }
    }
    ```

2. You can add data blocks in the checks to verify that a property of some resource outside the configuration or the scope of the module is correct. E.g., validate assumptions on VMs or clusters, check that resources are securely configured, or check that website responds with 200 OK after Terraform has run using the [`http` provider](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http).

    In the `dns_a_record` module. Write a check that uses the [`google_dns_managed_zone` data source](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/dns_managed_zone) and verifies that `visibility` is `"private"`.

    Apply the changes to the configuration.

3. To see the check from the previous step, you can run `terraform destroy` to deprovision the resources and then apply the configuration again. Note how it gives you a warning during the `plan` step, since the managed zone does not exist yet. Terraform will still provision the DNS records however, indepent of the state of the checks.

<!-- TODO
### Track G: Creating reusable modules

- Module structure and best practices
- Sharing modules within an organization
- Input/output variables and validation
- Module versioning strategies



->

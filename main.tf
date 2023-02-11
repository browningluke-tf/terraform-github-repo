locals {
  github_conf = yamldecode(var.repo_config)
  repos       = { for each in local.github_conf : each.name => each }
}

resource "github_repository" "repo" {
  for_each = local.repos

  # Meta
  name        = each.key
  description = lookup(each.value, "description", "")
  visibility  = lookup(each.value, "public", false) ? "public" : "private"
  is_template = lookup(each.value, "is_template", false)

  archived = lookup(each.value, "archived", false)

  # Has ...
  has_downloads = can(each.value.has.downloads) ? each.value.has.downloads : true
  has_issues    = can(each.value.has.issues) ? each.value.has.issues : true
  has_projects  = can(each.value.has.projects) ? each.value.has.projects : true
  has_wiki      = can(each.value.has.wiki) ? each.value.has.wiki : true

  # Init
  auto_init          = lookup(each.value, "init", false)
  gitignore_template = lookup(each.value, "gitignore", "")

  # Merges
  allow_auto_merge       = can(each.value.merge.auto) ? each.value.merge.auto : false
  delete_branch_on_merge = can(each.value.merge.delete_branch) ? each.value.merge.delete_branch : false

  allow_merge_commit = can(each.value.merge.types.commit) ? each.value.merge.types.commit : true
  allow_squash_merge = can(each.value.merge.types.squash) ? each.value.merge.types.squash : true
  allow_rebase_merge = can(each.value.merge.types.rebase) ? each.value.merge.types.rebase : true

  # Template
  dynamic "template" {
    for_each = can(each.value.template.owner) && can(each.value.template.repo) ? [each.value.template] : []

    content {
      owner                = template.value.owner
      repository           = template.value.repo
      include_all_branches = false
    }
  }
}

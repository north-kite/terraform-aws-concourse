A Terraform module to deploy a Concourse stack in AWS

Example usage to follow.

### Configuring Concourse to use SAML
`concourse_saml_conf` - (Optional) Specifies SAML config to use with e.g. Okta. Expects the following arguments:
* `enable_saml` - A boolean flag to enable or disable SAML configuration. Defaults false.
* `display_name` - Sets `CONCOURSE_SAML_DISPLAY_NAME` environment variable.
* `url` - Sets `CONCOURSE_SAML_SSO_URL` environment variable.
* `issuer` - Sets `CONCOURSE_SAML_SSO_ISSUER` environment variable.
* `ca_cert`- A string containing CA certificate. 
* `concourse_main_team_saml_group` - Sets `CONCOURSE_MAIN_TEAM_SAML_GROUP` environment variable.
* `concourse_saml_username_attr` - Sets `CONCOURSE_SAML_USERNAME_ATTR` environment variable.
* `concourse_saml_email_attr` - Sets `CONCOURSE_SAML_EMAIL_ATTR` environment variable.
* `concourse_saml_groups_attr` - Sets `CONCOURSE_SAML_GROUPS_ATTR` environment variable.

For details on environment variables see [Concourse SAML documentation](https://concourse-ci.org/generic-saml-auth.html).
Additional details on configuring attributes within Okta are available [here](https://github.com/concourse/concourse/pull/5998).

Example:
```
  concourse_saml_conf = {
    enable_saml                    = true
    display_name                   = "Okta"
    url                            = "https://my-name.okta.com/app/myapp/someid/sso/saml"
    issuer                         = "http://www.okta.com/abcdef"
    ca_cert                        = file("${path.module}/files/saml.cert")
    concourse_main_team_saml_group = "saml-group-name-admin"
    concourse_saml_username_attr   = "name"
    concourse_saml_email_attr      = "email"
    concourse_saml_groups_attr     = "groups"
  }
```
The example above assumes that a group named `saml-group-name-admin` has been created in Okta. This group will be added to `main` team in Concourse thus giving its members full Concourse admin permissions. 

### Configuring to use GitHub oAuth
`github_oauth_conf` - (Optional) - Specifies oAuth config to use with GitHub. This configuration
is likely GitHub specific, but may work with other oAuth providers as well.
* `enable_oauth` - A boolean flag to enable or disable the oAuth configuration. Default false.
* `display_name` - Sets `CONCOURSE_OAUTH_DISPLAY_NAME` env var.
* `concourse_github_client_id` - The Client ID provided by GitHub oAuth client creation.
* `concourse_github_client_secret` - The Client Secret provided by GitHub oAuth client creation.
* `concourse_main_team_github_org` - The name of the GitHub Organisation.
* `concourse_main_team_github_team` - The name(s) of the GitHub Team(s) with access.
* `concourse_main_team_github_user` - The name(s) of the GitHub User(s) with access.
```
  github_oauth_conf = {
      enable_oauth                    = true
      display_name                    = "GitHub"
      concourse_github_client_id      = "MY_CLIENT_ID"
      concourse_github_client_secret  = "MY_CLIENT_SECRET"
      concourse_main_team_github_org  = "MY_GITHUB_ORG"
      concourse_main_team_github_team = "MY_GITHUB_TEAM"
      concourse_main_team_github_user = "SOME_GITHUB_USER,SOME_OTHER_GITHUB_USER"
```

### Configuring to use GitLab oAuth
`gitlab_oauth_conf` - (Optional) - Specifies oAuth config to use with GitLab.
* `enable_oauth` - A boolean flag to enable or disable the oAuth configuration. Default false.
* `display_name` - Sets `CONCOURSE_OAUTH_DISPLAY_NAME` env var.
* `concourse_gitlab_client_id` - The Client ID provided by GitLab oAuth client creation.
* `concourse_gitlab_client_secret` - The Client Secret provided by GitLab oAuth client creation.
* `concourse_main_team_gitlab_group` - The name(s) of the GitLab Group(s) with access.
* `concourse_main_team_gitlab_user` - The name(s) of the GitLab User(s) with access.
```
  gitlab_oauth_conf = {
      enable_oauth                     = true
      display_name                     = "GitLab"
      concourse_gitlab_client_id       = "MY_CLIENT_ID"
      concourse_gitlab_client_secret   = "MY_CLIENT_SECRET"
      concourse_main_team_gitlab_group = "MY_GITLAB_GROUP"
      concourse_main_team_gitlab_user  = "SOME_GITLAB_USER,SOME_OTHER_GITLAB_USER"
```

### Configuring additional Concourse teams

`concourse_teams_conf` - (Optional) Specifies additional teams to create in Concourse. Expects the following:
* `key` - Name of the team 
* `value` - Role configuration in yaml format with a single field, `roles:`, pointing to a list of role authorization configs (see [Concourse docs](https://concourse-ci.org/managing-teams.html#setting-roles))
```
  concourse_teams_conf = {
    my_team_name = <<EOF
roles:
  - name: owner
    saml:
      groups: ["saml-group-name-admin"]
  - name: member
    saml:
      groups: ["saml-group-name-member"]
  - name: viewer
    saml:
      groups: ["saml-group-name-guest"]
EOF

  my_other_team_name = <<EOF
    roles:
  - name: owner
    saml:
      groups: ["saml-group-name-admin"]
  - name: viewer
    saml:
      groups: ["saml-group-name-member", "saml-group-name-guest"]
EOF
  }
```
The example above will create 2 teams in addition to `main` team, `infra` and `app`. In `infra` team,
* members of `saml-group-name-admin` SAML group will be given `owner` role within the team.
* members of `saml-group-name-member` SAML group will be given `member` role within the team.
* members of `saml-group-name-guest` SAML group will be given `viewer` role within the team.

For details on Concourse user roles see [Concourse documentation](https://concourse-ci.org/user-roles.html).

### Using custom IAM role with Concourse workers to enable cross-account access
By default this module will create an IAM role and associate it with worker instance profile. This role will be allowed to assume `ci` IAM role in the same account. However in more advanced scenarios where Concourse workers have to assume cross-account roles you'll have to create those roles and provide input to the module.
* `instance_iam_role` - (Optional) A string specifying name of the IAM role that will be associated with Concourse worker instance profile. The role must exist and have a trust policy set up so that EC2 service is allowed to assume it. 
* `worker_assume_ci_roles` - (Optional) - A list of IAM role ARNs that worker instance should be allowed to assume. 

Example:
Imagine a scenario with two AWS accounts, one called `mgmt` and another `dev`. Concourse is deployed to `mgmt` but should also be able to access `dev`. To enable this,
* create a role named `ci-worker` in `mgmt` account
* create a role named `ci` in both accounts
* configure both `ci` roles with trust policy that adds `arn:aws:iam::<mgmt-account-id>:role/ci-worker` to trusted entities
* when calling this module in `mgmt`, set
    * `instance_iam_role` to `ci-worker`
    * `worker_assume_ci_roles` to `[<ARN of ci role in mgmt>, <ARN of ci role in dev>]`

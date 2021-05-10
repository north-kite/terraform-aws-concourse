A Terraform module to deploy a Concourse stack in AWS

Example usage to follow.

`concourse_teams_conf` - (Optional) Specifies additional teams to create in Concourse. Expects the following:
* `key` - Name of the team 
* `value` - Role configuration in yaml format with a single field, `roles:`, pointing to a list of role authorization configs (see [Concourse docs](https://concourse-ci.org/managing-teams.html#setting-roles))
```
...
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
...
```

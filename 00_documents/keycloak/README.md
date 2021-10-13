# Keycloak IDM Overview

For the most part you can refer to the official documentation of Keycloak. It is well-written from a developer and an admin view:
- Glossary https://www.keycloak.org/docs/latest/server_admin/#core-concepts-and-terms
- Authorization https://www.keycloak.org/docs/latest/authorization_services/
- Admin Guide https://www.keycloak.org/docs/latest/server_admin/
- API Reference https://www.keycloak.org/docs-api/5.0/rest-api/index.html#_version_information

Also, if you want to locally setup your own keycloak to have a playground please refer to:
- Getting started Guide https://www.keycloak.org/docs/latest/getting_started/

Please create an issue, or give us a hint if you think the documentation is missing a topic.

## Access Links
IDM / Administration Console: https://idm.{STAGE}.{DOMAIN}.de/auth/<br>
User self service Console: https://idm.{STAGE}.{DOMAIN}.de/auth/realms/{YOUR_REALM}/account<br>
OIDC Values and Endpoints: https://idm.{STAGE}.{DOMAIN}.de/auth/realms/{YOUR_REALM}/.well-known/openid-configuration

The following documents will cover platform specifics and workflows the platform admin may encounter more frequently.

## Realm Configurations
- [Client and Roles](client_roles.md)
- [IDM Client Scopes](idm_scopes.md)
- [Password Policy](password_policy.md)

## Guides
- [User creation](create_user.md)
- [Add roles to a user](add_user_roles.md)
- [Tenant creation](create_tenant.md)
- [Add user to a tenant](add_user_to_tenant.md)
- [API Access](api_access.md)


Copyright © 2021 HYPERTEGRITY AG, omp computer gmbh. This work is licensed under a [CC BY SA 4.0 license](https://creativecommons.org/licenses/by-sa/4.0/).  
Author: Thomas Haarhoff, omp computer gmbh
## Customization

#### inventory
The inventory your main source for customizing the platform. This file and all of its content is described in the [Install documentation](INSTALL.md).

### Customization Files
This section shows file based customization regarding specific components.
#### keycloak
- **03_setup_k8s_platform/templates/keycloak/customization/email/messages_de.properties**<br>
This file contains the german templates for email content. This file is placed inside the keycloak-instances during the deployment. <br>
In order to deploy changes to this file, the GitLab-CI Task "Deploy_{STAGE}_Platfrom" needs to be triggered.

- **03_setup_k8s_platform/templates/keycloak/customization/images/keycloak-bg.png**<br>
This file contains the background image of the keycloak login screen. The file needs to be a png in order to get displayed and the target resolution should be 1920x1080. This file is placed inside the keycloak-instances during the deployment. <br>
In order to deploy changes to this file, the GitLab-CI Task "Deploy_{STAGE}_Platfrom" needs to be triggered.

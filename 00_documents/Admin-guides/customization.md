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

### Dump and Restore Geodata
Once a new platform has been deployed, the need of transferring geodata from one instance to the new one may arise.<br>
In order to achieve this, a dump of the old data has to be created, the data has to be restored in the new database and maybe access rights have to be adjusted.

- Dump<br>
```bash
# USER most likely is the `postgres` user
pg_dumpall -h {DOMAIN} -p 31876 -U {USER} -W -c > db.out
```

- Restore<br>
```bash
# The database for geodata is a postgis, so the DATABASE_POD is something like geodata-postgis-{...}
kubectl exec -i {{DATABASE_POD}} -- /bin/bash -c "PGPASSWORD={USER_PASS} psql --username {USER} {DATABASE_NAME}" < db.out
```

- Adjust permissions
If the username of the database user has changed, the database-owner has to be set to the new one, by executing the following SQL command:<br>
```bash
ALTER DATABASE {DATABASE_NAME} OWNER TO {NEW_DATABASE_USER}
```

> **Note**: Restoring a dump also recreates users with the same username alongside with adjusting the password. The easiest way to fix this, is to log in to pgadmin and change usernames to the desired. For the system to work properly, the passwords for the two users `WEBGIS_POSTGRES_ADMIN` and `MAPSERVER_POSTGIS_USER` (found in the inventory), have to be set properly.

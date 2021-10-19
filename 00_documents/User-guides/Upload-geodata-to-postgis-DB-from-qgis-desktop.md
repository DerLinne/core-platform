# How-to: Upload geodata from QGIS Desktop to Postgis DB

This how-to explains how to upload data from QGIS Desktop to postgis.


**pgAdmin roles/users and their rights:**
- A pgAdmin role _qgis_user_ was created by defining name and privileges

![ticket_65_7](/00_documents/User-guides/images/set_privileges.PNG)

- Individual users were created, mainly for the purpose of accessing the database via any Desktop GIS (QGIS or MapInfo) by defining the name, the password (Definition tab), activating "Can login?" (Privileges) and applying the role _qgis_user_ (Membership tab)

![ticket_65_6](/00_documents/User-guides/images/set_definition_and_membership.PNG)

**Loading geodata to the database using QGIS Desktop, two steps are required:**
1. Set up a database connection: 
- Open the Data Source Manager (see  highlighted button in the top-left corner in the screenshot below) 
- Set up a new connection filling in the following details: 
- Name: choose freely
- Host: { DOMAIN }
- Port: 31876
- Database: qwc_demo
- User credentials have to be added in the second tab ("Basic Authentication")

![ticket_65_1](/00_documents/User-guides/images/In_QGIS_create_db_connection_to_PostGIS.PNG)

2. Open the Database Manager to upload geodata:

![ticket_65_2](/00_documents/User-guides/images/find_db_manager.png)
- In QGIS Data Manager, select the  "Import Layer ..." button and fill in the relevant details

![ticket_65_3](/00_documents/User-guides/images/import_layer_to__PostGIS_db.PNG)

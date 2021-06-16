**How-to: Upload geodata from QGIS desktop to Postgis DB**

This how-to explains how to upload data from QGIS desktop to postgis.


**pgAdmin roles/users and their rights:**
- A pgAdmin role _qgis_user_ was created by defining name and privileges
![ticket_65_7](/uploads/acc22e8479f2f8a37e1fd65c826d13bc/ticket_65_7.PNG)

- Individual users were created, mainly for the purpose of accessing the database via any Desktop GIS (QGIS or MapInfo) by defining name, a password (Definition tab) and applying the role _qgis_user_ (Membership tab)
![ticket_65_6](/uploads/ea5e010ed4fb4796f7eed825c5c7adde/ticket_65_6.PNG)

**Loading geodata to the database using QGIS Desktop, two steps are required:**
1. Set up a database connection: 
- Open the Data Source Manager (see  highlighted button in the top-left corner in the screenshot below) 
- Set up a new connection filling in the following details: 
- Name: choose freely
- Host: utr-k8s.urban-data.cloud
- Port: 31876
- Database: qwc_demo
- User credentials have to be added in the second tab ("Basic Authentication")
![ticket_65_1](/uploads/97a92d6974c8be6eb744b6bb31856ca3/ticket_65_1.PNG)

2. Open the Database Manager to upload geodata:
![ticket_65_2](/uploads/9338cc3cdd71e668023a97ab00a483c2/ticket_65_2.png)
- In QGIS Data Manager, select the  "Import Layer ..." button and fill in the relevant details
![ticket_65_3](/uploads/bc678b351b9b8ad9d2bd0c28df5ac990/ticket_65_3.PNG)

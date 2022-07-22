# Data Warehouse Cloud PowerBI Connector

## About
This is a PoC for using DWC Public OData APIs with PowerBI.

The connector provides a more seamless OAuth authetication proccess, which only requires the user generate the OData Client in SAC and provide its own credentials into a SAC standard authentication page

## Using the connector

1. Download the **DWC.mez** file and copy it into windows foldes ~/Doc
uments/Power BI Desktop/Custom Connectors/.
2. In PowerBI click on **Get Data** > **Others** and search for *SAP Data Warehouse Cloud*
3. Select *SAP Data Warehouse Cloud* and connect
4. It will ask for your `dwc_url`, provide there the DWC Tenant URL (eg: https://dwc-starkiller-hc-c4s-ga.starkiller.hanacloudservices.cloud.sap/)
5. If you are not authenticate with your DWC, click on **Sign In User**
6. A browser will opening requesting for your user email and password, provide it
7. That is it! Wait for the connection to be completed


For now the connecctor is just a PoC and the authentication URLs are fixed to the starkiller C4S environment, in case you want to use a different tenant or environemnt update the URLs in to the `dwc.pq` file and rebuild the extension.

## Building Using VSCode

The PowerBI extensions require a .mez file to to be imported into PowerBI, to generate one follow the steps:

1. Select all files into the repo and zip tem into a .zip file
2. Renamed the file to have the extension **.mez**
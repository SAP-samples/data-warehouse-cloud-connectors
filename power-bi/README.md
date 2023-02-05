# Data Warehouse Cloud PowerBI Connector
<!---
SPDX-License-Identifier: Apache-2.0
SPDX-FileCopyrightText: 2022 SAP SE or an SAP affiliate company and sap-data-warehouse-cloud contributors
--->
## News
The OData API of SAP DataWarehouseCloud has been updated. Please upgrade to the new version 1.40.
What's new with Version 1.40?
 - data refresh after publishing to PowerBi Web is now possible
 - restructure parameter/connection screen: the catalog search and data access has been split into two connections.
   The option to limit the row cound ($top) has been removed. Now PowerBi uses a default of 1000 for the preview and unlimited for data access 
 - the structure of connection.json file has changed to handle several system and system types. The latter is a preparation to support SAC.
 - the property host name now expects the host name (without https://) and not the URL anymore

## About
This is a sample for using SAP Data Warehouse Cloud OData APIs with PowerBI. The following sections decribe how to download, configure and deploy the custom connector for PowerBi. Despite the creation of an OAuth client, all tasks are client-side only.

To get a visual impression on using the custom connecter, please visit the blog post [SAP Data Warehouse Cloud: OData Connector for PowerBi](https://blogs.sap.com/2022/10/14/sap-data-warehouse-cloud-odata-connector-for-powerbi/)

# Configure SAP Data Warehouse Cloud
Please logon to your tenant and open the _**App Integration**_ tab (Navigate via System => Administration => Tab App Integration).

Now we have to create an oauth client, that will be used by the custom connector. Note that this client is not the business user but authorizes the custom connector client only. At runtime, the user will be directed to his Identity Provider.

1. On tab _**App Integration**_, select the option "Add new OAuth Client"
2. Use the following values for the client configuration:
- Name: PowerBi OAuth Client
- Purpose: interactive Usage
- Redirect URI: https://oauth.powerbi.com/views/oauthredirect.html

Upon saving the system with automatically generate a client id and client secret (=passwort). These two parameters will be required later upon configuration of the custom connection on the client side.

Leave this page open, as need to look up additional information like the token and authorization URL later.
# MS PowerBi - Custom Connector
Now we start with the client part. As the MS PowerBi client is MS Windows only, you require a MS Windows pc to continue.
## Download
The folder "power-bi" contains all data required for the custom connector. Either download these files or clone the git repository (recommended).
## Configure
The implementation of the connector is generic - the only task we have to do is to add your tenant specific information to the file "connections.json".

_*Content of "connections.json"*_
```json
[{
    "product":"DWC",
    "host": "<tenant URL>",

    "client_id": "<client id>",
    "client_secret": "<client secret>",

    "auth_token_url": "<token URL></oauth/token>",
    "auth_authorize_url": "<authorize URL></oauth/authorize>"
}]
```
Please replace the dummy values based on the instructions below.

### _"host"_
> Tenant URL, e.g. https://my-tenant.eu10.hcs.cloud.sap (without a “/” at the end !). 
### _"auth_token_url"_
> Copy the token URL from the _**App Integration**_ tab (URL typically ends with /token)
### _"auth_authorize_url"_
> Copy the authorization URL from the _**App Integration**_ tab (typically ends with /authorize)
### _"client_id"_
> Use the client id generated in the previous chapter.
### _"client_secret"_ 
> Use the client secret generated in the previous chapter.

Now that we have all required information in place, apply the changes to the file connections.json and save it to your folder.

## Build the connector
For building and packaging: Just zip the whole content of the power-bi folder into an archive named e.g. "SAP_DWC_01" (Note: The content of the folder only - excluding the folder itself). 

Change the extension from *.zip to *.mez to make it a custom connector. This file extension is required for MS PowerBi. Done.

## Deploy the connector
Ensure that the following folders exists - if not, please create them:

 - Navigate to your document folder
 - Create folder “Power BI Desktop”
 - Create subfolder “Custom Connectors"

 Copy the custom connector file "SAP_DWC_01.mez" to the folder "Custom Connectors".

## Test - Deployment
1. Start MS PowerBi - if your security settings are on default (recommended), MS PowerBi should show a pop-up indicating that a custom connector has been found - but it will not be active.

   > _Test passed_: MS PowerBi found the file and interpreted the content as "custom connector"

2. Adjust the security settings ([see video](https://sapvideoa35699dc5.hana.ondemand.com/?entry_id=1_75xzgxg4)) to "Allow any extension to load without validation". Close and re-open MS PowerBi. The pop-up should not show up any more. 

    >_Test passed_: security settings are OK

3. Start from a blank query and choose the "Get data" option. On the list select the "More ..." and search for SAP. Now you should see a connector with the name "SAP Data Warehouse Cloud" ([see video](https://sapvideoa35699dc5.hana.ondemand.com/?entry_id=1_ucqxh3pa)).

    >_Test passed_: The registration of the custom connectors was successfull.

## Next Steps
Follow the scenarios outlined in the [SAP Data Warehouse Cloud: OData Connector for PowerBi](https://blogs.sap.com/2022/10/14/sap-data-warehouse-cloud-odata-connector-for-powerbi/) - search for an OData Service and load your first data. Then start building your MS PowerBi applications based on data imported from SAP Data Warehouse Cloud. 

And finally: Don't miss to leave your comments or questions!

## Outlook
Once this is working on local PC you might want to use it in the context of the browser based MS PowerBi and e.g. trigger or schedule a data refresh from there. This possible using the "on-premise data gateways". See [service-gateway-custom-connectors](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors) for more details.

**Current status:** So far we managed to deploy the customer connector and see it recognized in the web app. Unfortunately, the authentication using the oauth-flow is failing - the browser dialog appears and it seems not to be able to fetch and store the token.

# Appendix
For a technical background of PowerBi Custom Connectors, please check out the following pages:
 - [Development and Test Environment](https://learn.microsoft.com/en-us/power-query/installingsdk)
 - [Tutorial TripPin](https://learn.microsoft.com/en-us/power-query/samplesdirectory#trippin)
 - [service-gateway-custom-connectors](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors)

 For documenation around SAP Data Warehouse Cloud - OData:
  - [Blog Post: Connecting with PowerBi via a blank query](https://blogs.sap.com/2022/09/23/connecting-sap-data-warehouse-cloud-odata-api-with-powerbi-via-a-blank-query-2/)
  - [SAP Help - OData](https://help.sap.com/docs/SAP_DATA_WAREHOUSE_CLOUD/c8a54ee704e94e15926551293243fd1d/7a453609c8694b029493e7d87e0de60a.html)
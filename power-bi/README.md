# Data Warehouse Cloud PowerBI Connector
<!---
SPDX-License-Identifier: Apache-2.0
SPDX-FileCopyrightText: 2022 SAP SE or an SAP affiliate company and sap-data-warehouse-cloud contributors
--->
## News 1.80

**New connection type for generic OData URL**  
A third connections type has been introduced allowing you to provide the full Odata service URL. The current connections for catalog and data come with a dialog asking for space, view, parameters etc. Based on these entities the OData service URL is determined. The new connection type offers you to directly enter the full URL.  

  **Motivation for this new connection type:**  
 - There are plans to offer a "copy OData URL"-option in the design time of SAP Datasphere. The new connection type is the counterpart to complete the scenario by offering a "paste" target.  
 - You are not restricted to SAP Datasphere any more. As an example, you could connect to the SAP Analytics OData APIs as well. Other OData APIs which use the same authentication flow should work as well (not tested so far - feedback welcome).

**Usage**  
As we still need the system configuration (e.g. for OAuth client id and secret), the system must be selected.
Enter the full path of the OData Serivce in the input field for "path". It must start with a "/".  
Note: I have decided for the explicit selection of host name - instead of parsing the URL and search for host in the config file - as it reduces one source of errors (feedback welcome).

**Example**  
The service URL: _https://\<my-tenant\>.eu10.hcs.cloud.sap/dwaas-core/odata/v4/consumption/relational/\<mySpace\>\<myView\>_ is split into two fields for host and path:
  |Dialog Field| Content|
  |---------|------------------|
  |Host:| \<my-tenant\>.eu10.hcs.cloud.sap (select from drop-down)|
  |Path:|/dwaas-core/odata/v4/consumption/relational/\<mySpace\>/\<myView\>| 
        
## News 1.70
What's new with Version 1.70?
- **Switch between relational and analytical access:**  
So far, the data access for always relational. As a consequence, e.g. no data aggregation takes place if you exclude columns in PowerBi. Now you can select between relational and analytical access. In the latter you see aggregation of data and associations resolved.

  |View Type| Relational Access| Analytical Access|
  |---------|------------------|------------------|
  |relational|    yes | no |
  |analytical dataset| yes | yes|
  |analytic model | no | yes |

- **Support for Analytic Model**  
Select analytical access on the connection screen. If you observe an error like "Internal Server Error Error: Result cannot be empty" please re-deploy the Analytic Model. This resolved the issue in some cases. 
- **Input Parameter Support**:  
Enter the input paramters seperated by comma in the format: _column1='value1',column2='value2'_

**Hint for input parameters: Errors**  
The error message "Expected at least one key predicate but found none" indicates a missing mandatory parameter. Check your spelling or verify the name with the OData metadata defintion.  
Where to find the parameter definiton: search for the EntityType with "_Name=\<viewname\>Parameters_". Each key entry below represents a parameter.

**Hint for input parameters: Entry Point Changed**  
The parameters are set on the entity/view itself. When using parameters, the connector preselects the entity with the view name and adds the parameters. This is different to the non-parameter case, where the connector returns the URL of the service. Here the PowerBi user can/must select an entity/view.

## News 1.50
What's new with Version 1.50?
 - Renaming from DWC to Data Sphere
 - Fetching new authentication token based on refresh token fixed
 - Data refresh and scheduling for published reports is now working (requires MS on-prem gateway) 

## News 1.40
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
    "host": "<host name - without https://>",

    "client_id": "<client id>",
    "client_secret": "<client secret>",

    "auth_token_url": "<token URL></oauth/token>",
    "auth_authorize_url": "<authorize URL></oauth/authorize>"
}]
```
Please replace the dummy values based on the instructions below.

### _"host"_
> host name, e.g. my-tenant.eu10.hcs.cloud.sap (without a “/” at the end !). 
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

**Current status:** With the version 1.50 the data refresh is now fully supported incl. a scheduled data refresh. Please let me know if you still find issues here.

# Appendix
For a technical background of PowerBi Custom Connectors, please check out the following pages:
 - [Development and Test Environment](https://learn.microsoft.com/en-us/power-query/installingsdk)
 - [Tutorial TripPin](https://learn.microsoft.com/en-us/power-query/samplesdirectory#trippin)
 - [service-gateway-custom-connectors](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors)

 For documenation around SAP Data Warehouse Cloud - OData:
  - [Blog Post: Connecting with PowerBi via a blank query](https://blogs.sap.com/2022/09/23/connecting-sap-data-warehouse-cloud-odata-api-with-powerbi-via-a-blank-query-2/)
  - [SAP Help - OData](https://help.sap.com/docs/SAP_DATA_WAREHOUSE_CLOUD/c8a54ee704e94e15926551293243fd1d/7a453609c8694b029493e7d87e0de60a.html)

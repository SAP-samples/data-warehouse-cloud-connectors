# Data Warehouse Cloud PowerBI Connector

## About
This is a PoC for using DWC Public OData APIs with PowerBI.

## Download Connector
The folder power-bi contains all data required for the custom connector. Either download these files or clone the git repository (recommended).

## Configure the Connector
The implementation of the connector is generic - the only task we have to do is to add your tenant specific information to the file "connections.json". Replace the dummy values <value> with your data.
```json
{
    "host": "<tenant URL>",

    "client_id": "<client id>",
    "client_secret": "<client secret>",

    "auth_token_url": "<token URL></oauth/token>",
    "auth_authorize_url": "<authorize URL></oauth/authorize>"
}
```
**host**: this is the tenant URL, e.g. https://my-tenant.eu10.hcs.cloud.sap (without a “/” at the end !). 

For the next infos, please logon to your tenant and open the _App Integration_ tab (Navigate via System => Administration => Tab App Integration)

**auth_token_url**: this is the URL with title Token URL (typically ends with /token)

**auth_authorize_url**: this is the URL with title Authorization URL (typically ends with /authorize)

Now we have to create an oauth client, that will be used by the custom connector. Note that this client is not the business user but authorizes the custom connector client only. At runtime, the user will be directed to his Identity Provider.

1. Select the option "Add new OAuth Client"
2. Use the following values for the client configuration:
- Name: PowerBi OAuth Client
- Purpose: interactive Usage
- Redirect URI: https://oauth.powerbi.com/views/oauthredirect.html

Upon saving the system with automatically generate an client id and secret (=passwort). You might need to re-open after saving to see these values:

**client_id**: copy the long uid-like id (field name is OAuth Client Id)

**client_secret**: copy the secret (field name secret)

Now that we have all required information in place, apply the changes to the file connections.json and save it to your folder.

## Build the connector
For building and packaging: just zip the whole content of the power-bi folder (just the content of the folder - excluding the folder itself). Change the extension from zip to mez. Ignore any complains of the file explorer.

## Deploy the connector
Ensure that the following folder exists. If not, please create the missing folder structur:

Navigate to your document folder and search for: “Power BI Desktop” - create if required
Create a subfolder for “Power BI Desktop” with the name “Custom Connectors"

## Test - Deployment
1. Start MS PowerBi - if your security settings are on default (recommended), MS PowerBi should show a pop-up indicating that a custom connector has been found - but it will not be active.

    _Test passed_: MS PowerBi found the file and interpreted the content as "custom connector"

2. Adjust the security settings (see video in blog post) to "Allow any extension to load without validation". Close and re-open MS PowerBi. The pop-up should not show up any more. 

    _Test passed_: security settings are OK

3. Start from a blank query and choose the "Get data" option. On the list select the "More ..." and search for SAP. Now you should see a connector with the name "SAP Data Warehouse Cloud".

    _Test passed_: The registration of the custom connectors was successfull.

## Next Steps
Follow the scenarios outlined in the blog post - search for an OData Service and load your first data. Don't miss to leave your comments or questions.

## Outlook
Once this is working on local PC you might want to use it in the context of the browser based MS PowerBi and e.g. trigger or schedule a data refresh from there. This possible using the "on-premise data gateways". 

Current status: So far we managed to deploy the customer connector and see it recognized in the web app. Unfortunately, the authentication using the oauth-flow is failing - the browser dialog appears and it seems not to be able to fetch and store the token.
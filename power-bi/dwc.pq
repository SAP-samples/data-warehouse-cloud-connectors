section SapDataWarehouseCloudConnector;

// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2022 SAP SE or an SAP affiliate company and sap-data-warehouse-cloud contributors

// Connection Infos for SAC and DWC Systems
connections = Json.Document(Extension.Contents("connections.json"));

redirect_uri    = "https://oauth.powerbi.com/views/oauthredirect.html";
windowWidth     = 1200;
windowHeight    = 1000;
version         = "1.50";

product_SAC     = "SAC";
product_DWC     = "DWC";


// Enhance parameter screen by e.g. list of permitted values or text
// https://docs.microsoft.com/en-us/power-query/handlingdocumentation

// Definition of the Initial Dialog for SAP DWC
// --------------------------------------------
hostCustomDWC = type text meta [
        Documentation.FieldCaption      = Extension.LoadString("DWC_HostCaption"),
        Documentation.FieldDescription  = Extension.LoadString("DWC_HostDescription"),
        Documentation.AllowedValues     = Table.FromRecords(List.Select(connections, each Record.Field(_,"product") = product_DWC))[host]
    ];

selectOptionDWC = [catalog = "1. "& Extension.LoadString("ODataSeriveTypeSearch"), 
                   viewRel = "2. "& Extension.LoadString("ODataServiceTypeDWCView")];

serviceSelectionDWC = type text meta [
        Documentation.FieldCaption      = Extension.LoadString("ODataServiceTypeCaption"),
        Documentation.FieldDescription  = Extension.LoadString("ODataServiceTypeDescription"),
        Documentation.AllowedValues     = { selectOptionDWC[catalog], selectOptionDWC[viewRel] },
        DataSource.Path = false
    ];
spaceNameDWC = type text meta [
        Documentation.FieldCaption      = Extension.LoadString("DWC_SpaceCaption"),
        Documentation.FieldDescription  = Extension.LoadString("DWC_SpaceDescription"),
        DataSource.Path = false
    ];

viewNameDWC = type text meta [
        Documentation.FieldCaption      = Extension.LoadString("DWC_ViewCaption"),
        Documentation.FieldDescription  = Extension.LoadString("DWC_ViewDescription"),
        DataSource.Path = false
    ];

// Custom Connector Registration for SAP DWC
// -------------------------------------------
dwcFunction = type function (
    host   as hostCustomDWC,
    space  as spaceNameDWC,
    view   as viewNameDWC
    ) as any meta [
        Documentation.Name = Extension.LoadString("DWC_PopUp_ReadData")
    ];

dwcFunctionCatalog = type function (
    host            as hostCustomDWC,
    optional space  as spaceNameDWC,
    optional view   as viewNameDWC
    ) as any meta [
        Documentation.Name = Extension.LoadString("DWC_PopUp_CatalogSearch")
    ];

[DataSource.Kind="SapDataWarehouseCloudConnector", Publish="SapDataWarehouseCloudConnector.UI"]
shared SapDataWarehouseCloudConnector.Contents = 
    Value.ReplaceType(SapDataWarehouseCloud.Contents, dwcFunction);

   shared SapDataWarehouseCloud.Contents = (host as text, space as text, view as text) =>
    let
        selectedSource = "2. " & "ODataServiceTypeDWCView",
        log_host_msg = "Method SapDataWarehouseCloud.Contents reached ",
        log_host = Diagnostics.Trace(TraceLevel.Information,log_host_msg, () => let result = log_host_msg in result, true),

        service_url = getServiceURL(product_DWC, host, selectedSource, space, view),

        log_serviceURL_msg = "Method SapDataWarehouseCloud.Contents ServiceUrl=" & service_url,
        log_serviceURL = Diagnostics.Trace(TraceLevel.Information, log_serviceURL_msg, () => let result = log_serviceURL_msg in result, true),

        source = enforceFunctionUsage(OData.Feed(service_url),{log_host, log_serviceURL})
    in
        source;

[DataSource.Kind="SAPDWC_Catalog", Publish="SAPDWC_Catalog.UI"]
shared SAPDWC_Catalog.Contents = 
    Value.ReplaceType(SAPDWC_Catalog_Impl.Contents, dwcFunctionCatalog);

   shared SAPDWC_Catalog_Impl.Contents = (host as text, optional space as text, optional view as text) =>
    let
        selectedSource = "1. " & "ODataSeriveTypeSearch",
        log_host_msg = "Method SapDataWarehouseCloud.Contents reached ",
        log_host = Diagnostics.Trace(TraceLevel.Information,log_host_msg, () => let result = log_host_msg in result, true),

        service_url = getServiceURL(product_DWC, host, selectedSource, space, view),

        log_serviceURL_msg = "Method SapDataWarehouseCloud.Contents ServiceUrl=" & service_url,
        log_serviceURL = Diagnostics.Trace(TraceLevel.Information, log_serviceURL_msg, () => let result = log_serviceURL_msg in result, true),

        source = enforceFunctionUsage(OData.Feed(service_url),{log_host, log_serviceURL})
    in
        source;

// Shared functions between SAC and DWC connector
// ----------------------------------------------

getServiceURL = (product as text, host as text, selectedSource as text, space as nullable text, view as nullable text) =>
    let

        catalog_path_DWC = "/dwaas-core/odata/v4/catalog/assets",

        // use first char as "key"
        useCatalogService       = if Text.At(selectedSource,0) = "1" then true else false,
        useRelationalService    = if Text.At(selectedSource,0) = "2" then true else false,
        useSACProviderService   = if Text.At(selectedSource,0) = "3" then true else false,

        tenantURL = "https://" & host,

        service_url_catalog = 
            if useCatalogService = true and product = product_DWC then
                Uri.Combine(tenantURL, catalog_path_DWC) & "?" & getCatalogParamsDWC(space, view)
            else "",

        hasParamWithNull  = if space = null or view = null then true else false,
        service_url_relational =
            if useRelationalService = true and product = product_DWC then
                if hasParamWithNull = false then
                    getServiceURLConsumptionDWC(tenantURL, catalog_path_DWC, space, view)
                else 
                    error "Parameters for Space and View must be provided."
            else "",

        service_url = service_url_catalog & service_url_relational,

        check = if service_url = "" then
                    error "Unknown OData Service Type."
                else ""
            
     in service_url
;

getServiceURLConsumptionDWC = ( tenantURL as text, catalog_path as text, space as text, view as text) =>
    let
        asset_search_url = tenantURL & catalog_path & "?" & getCatalogParamsDWC(space, view),
        Response  = Web.Contents(
            asset_search_url, 
            [ Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"]]),
        Parts = Json.Document(Response),

        serviceFound = not List.IsEmpty(Parts[value]),

        service_url = if serviceFound = true 
            then 
                if List.Count(Parts[value]) = 1 then
                    List.First(Parts[value])[assetRelationalDataUrl]
                else
                    error "Found more/less than one service with the given space and view names/patterns. Count is " & List.Count(Parts[value])
            else 
                error "The requested SAP DWC service for space "& space &" and view "& view &" could not be found."

    in service_url;

getCatalogParamsDWC = (space as nullable text, view as nullable text) =>
    let

        params = 
                if space <> null and view = null
                then "$filter=" & Uri.EscapeDataString("spaceName eq '"& space &"'")
            else 
                if view <> null and space = null
                then "$filter=" & Uri.EscapeDataString("name eq '"& view &"'") 
            else 
                if view <> null and view <> null 
                then "$filter=" & Uri.EscapeDataString("spaceName eq '"& space &"'") & " and " & Uri.EscapeDataString("name eq '"& view &"'")
            else ""
    in
        params
;

enforceFunctionUsage = (value as any, traces as list) =>
    let
        result = if List.NonNullCount(traces) > 0 then value else value
    in
        result;

shared SapDataWarehouseCloudConnector.TestConnection = (host as text) =>
    let
        // The current credentials can be retrieved using the Extension.CurrentCredential() function.
        // See: https://docs.microsoft.com/en-us/power-query/handlingauthentication
        result = true
    in 
        result;

shared SapAnalyticsCloudConnector.TestConnection = (host as text) =>
    let
        // The current credentials can be retrieved using the Extension.CurrentCredential() function.
        // See: https://docs.microsoft.com/en-us/power-query/handlingauthentication
        result = true
    in 
        result;

SapDataWarehouseCloudConnector = [
    TestConnection = (host) => {"SapDataWarehouseCloudConnector.TestConnection", host},
    Authentication = [
        OAuth = [
              StartLogin  = StartLoginDWC
            , FinishLogin = FinishLogin
            , Refresh     = Refresh_DWC
            ]
         ]
];

SAPDWC_Catalog = [
    TestConnection = (host) => {"SapDataWarehouseCloudConnector.TestConnection", host},
    Authentication = [
        OAuth = [
              StartLogin  = StartLoginDWC
            , FinishLogin = FinishLogin
            , Refresh     = Refresh_DWC
            ]
         ]
];

SapDataWarehouseCloudConnector.UI = [
    Beta = true,
    dataSourceLabel = Extension.LoadString("ConnectionTitleDWC") & " - Data"& " (" & version & ")",
    ButtonText      = { dataSourceLabel, Extension.LoadString("FormulaHelp") },
    SourceImage     = SapDataWarehouseCloudConnector.Icons,
    SourceTypeImage = SapDataWarehouseCloudConnector.Icons
];

SAPDWC_Catalog.UI = [
    Beta = true,
    dataSourceLabel = Extension.LoadString("ConnectionTitleDWC")& " - Catalog"& " (" & version & ")",
    ButtonText      = { dataSourceLabel, Extension.LoadString("FormulaHelp") },
    SourceImage     = SapDataWarehouseCloudConnector.Icons,
    SourceTypeImage = SapDataWarehouseCloudConnector.Icons
];

SapDataWarehouseCloudConnector.Icons = [
    Icon16 = { Extension.Contents("dwc16.png"), Extension.Contents("dwc20.png"), Extension.Contents("dwc24.png"), Extension.Contents("dwc32.png") },
    Icon32 = { Extension.Contents("dwc32.png"), Extension.Contents("dwc40.png"), Extension.Contents("dwc48.png"), Extension.Contents("dwc64.png") }
];

SAPDWC_Catalog.Icons = [
    Icon16 = { Extension.Contents("dwc16.png"), Extension.Contents("dwc20.png"), Extension.Contents("dwc24.png"), Extension.Contents("dwc32.png") },
    Icon32 = { Extension.Contents("dwc32.png"), Extension.Contents("dwc40.png"), Extension.Contents("dwc48.png"), Extension.Contents("dwc64.png") }
];

// Docu: https://learn.microsoft.com/en-us/power-query/handlingauthentication#implementing-an-oauth-flow
StartLoginDWC = (dataSourcePath, state, display) =>
    let
        connectionsByProduct = List.Select(connections, each Record.Field(_,"product") = product_DWC),
        result = StartLogin(dataSourcePath, state, display, connectionsByProduct)
    in
        result;

StartLogin = (dataSourcePath, state, display, connections) =>
    let
        host = Json.Document(dataSourcePath)[host],
        connectionsFoundByHost = List.Select(connections, each Record.Field(_,"host") = host),
        connection = List.First(connectionsFoundByHost),

        AuthorizeUrl = connection[auth_authorize_url] & "?" & Uri.BuildQueryString(
            [
                client_id = connection[client_id],
                response_type = "code",
                state = state
            ])
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = windowHeight,
            WindowWidth = windowWidth,
            Context = connection
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        Parts = Uri.Parts(callbackUri)[Query]
    in
        TokenMethod(Parts[code], context);

TokenMethod = (code, connection) =>
    let
         BasicAuth = Binary.ToText(Text.ToBinary(connection[client_id] & ":" & connection[client_secret]),0),
         Response  = Web.Contents(
            connection[auth_token_url], 
            [Content = Text.ToBinary(Uri.BuildQueryString(
                [
                    code = code,
                    grant_type = "authorization_code",
                    response_type = " token"
                ])),
                Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json", #"Authorization" = "Basic " & BasicAuth]
            ]),
        TokenList = Json.Document(Response)
    in
        TokenList;

Refresh_DWC = (dataSourcePath, oldCredential) => 
    let
        product = product_DWC,
        result = Refresh(product, dataSourcePath, oldCredential)
    in
        result;

 Refresh = (product, dataSourcePath, oldCredential) => 
    let
        host = Json.Document(dataSourcePath)[host],
        connectionsByProduct = List.Select(connections, each Record.Field(_,"product") = product),
        connectionsByHost    = List.Select(connectionsByProduct, each Record.Field(_,"host") = host),
        connection = List.First(connectionsByHost),

        BasicAuth = Binary.ToText(Text.ToBinary(connection[client_id] & ":" & connection[client_secret]),0),

        refreshToken = oldCredential,

        Request = Text.ToBinary(Uri.BuildQueryString(
                         [   refresh_token = refreshToken,
                                grant_type = "refresh_token" ] )),

        RequestHeaders = [ #"Content-type" = "application/x-www-form-urlencoded"
                          ,#"Accept" = "application/json"
                          ,#"Authorization" = "Basic " & BasicAuth ],

        Response = Web.Contents(
                      connection[auth_token_url], 
                      [ Content = Request,
                        Headers = RequestHeaders ]),

        NewTokenList = Json.Document(Response)
    in
        NewTokenList;
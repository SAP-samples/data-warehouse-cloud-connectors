section SapDataWarehouseCloudConnector;

// Connection Infos for DWC System
connections = Json.Document(Extension.Contents("connections.json"));

redirect_uri    = "https://oauth.powerbi.com/views/oauthredirect.html";
windowWidth     = 1200;
windowHeight    = 1000;
version         = "0.44";

// Callback functions for PowerBi Customer Connector
// Enhance parameter screen by e.g. list of permitted values or text
// https://docs.microsoft.com/en-us/power-query/handlingdocumentation

// Custom Type for host - provide permitted values
hostCustom = type text meta [
        Documentation.FieldCaption = "SAP DWC Tenant URL:",
        Documentation.FieldDescription = "Select the tenant URL of your DWC System.",
        Documentation.AllowedValues = { connections[host] }
    ];

topCustom = type number meta [
        Documentation.FieldCaption = "Number of Rows to be fetched:",
        Documentation.FieldDescription = "Select the number of rows to be fetched. This is translated into $top of OData.",
        Documentation.SampleValues = {100}
    ];

selectOption = [catalog = "1. search for available OData services", viewRel ="2. read data from OData service"];

serviceSelection = type text meta [
        Documentation.FieldCaption = "Select OData Service Type:",
        Documentation.FieldDescription = "Please choose your service type: catalog to browse for odata services or select directly a view.",
        Documentation.AllowedValues = { selectOption[catalog], selectOption[viewRel] }
    ];

dwcFunction = type function (
    host as hostCustom,
    selectedSource as serviceSelection,
    optional space as text,
    optional view as text,
    optional top as topCustom
    ) as any meta [
        Documentation.Name = "SAP Data Warehouse Cloud - OData"
    ];

[DataSource.Kind="SapDataWarehouseCloudConnector", Publish="SapDataWarehouseCloudConnector.UI"]
shared SapDataWarehouseCloudConnector.Contents = 
    Value.ReplaceType(SapDataWarehouseCloud.Contents, dwcFunction);

 shared SapDataWarehouseCloud.Contents = (host as text, selectedSource as text, optional space as text, optional view as text, optional top as number) =>
    let
        // Overwrite entered value with fixed host from configuration
        host = connections[host],

        log_host_msg = "Method SapDataWarehouseCloud.Contents reached ",
        log_host = Diagnostics.Trace(TraceLevel.Information,log_host_msg, () => let result = log_host_msg in result, true),

        service_url = getServiceURL(host, selectedSource, space, view, top),

        log_serviceURL_msg = "Method SapDataWarehouseCloud.Contents ServiceUrl=" & service_url,
        log_serviceURL = Diagnostics.Trace(TraceLevel.Information, log_serviceURL_msg, () => let result = log_serviceURL_msg in result, true),

        source = enforceFunctionUsage(OData.Feed(service_url),{log_host, log_serviceURL})
    in
        source;

getServiceURL = (host as text, selectedSource as text, space as nullable text, view as nullable text, optional top as number) =>
    let

        top_rows  = if top is null then "1000" else Number.ToText(top),

        catalog_path        = "/dwaas-core/odata/v4/catalog/assets",
        consumption_path    = "/dwaas-core/odata/v4/consumption/relational",

        // use first char as "key"
        useCatalogService = if Text.At(selectedSource,0) = "1" then true else false,
        useRelationalService = if Text.At(selectedSource,0) = "2" then true else false,
        hasParamWithNull  = if space = null or view = null then true else false,

        service_url = 
            if useCatalogService = true 
                then Uri.Combine(connections[host], catalog_path) & getCatalogParams(space, view, top_rows)                
                else if useRelationalService = true then
                    if hasParamWithNull = false then
                        Uri.Combine(connections[host], consumption_path)   & getConsumptionParams(space, view, top_rows)
                    else error "Parameters for Space and View must be provided."
                else error "Unknown OData Service Type."

     in service_url
;

getConsumptionParams = (space as text, view as text, top as text) =>
    let
        params =  "/" 
                & Uri.EscapeDataString(space) 
                & "/" 
                & Uri.EscapeDataString(view) 
                & "/" 
                & Uri.EscapeDataString(view) 
                & "?"
                & "$top=" & Uri.EscapeDataString(top)
    in
        params;

getCatalogParams = (space as nullable text, view as nullable text, top as text) =>
    let
        top_param = "$top=" & top,

        read_catalog_all = if space =  null and view =  null 
            then "?" & top_param 
            else null,

        read_catalog_space = if space <> null and view =  null 
            then "?" & top_param & "&" & "$filter=" & Uri.EscapeDataString("space_name eq '"& space &"'")
            else null,

        read_catalog_view  = if space =  null and view <> null 
            then "?" & top_param & "&" & "$filter=" & Uri.EscapeDataString("name eq '"& view &"'") 
            else null,

        params = 
                 if read_catalog_all    <> null then read_catalog_all
            else if read_catalog_space  <> null then read_catalog_space
            else if read_catalog_view   <> null then read_catalog_view
            else null
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

SapDataWarehouseCloudConnector = [
    TestConnection = (host) => {"SapDataWarehouseCloudConnector.TestConnection", host},
    Authentication = [
        OAuth = [
              StartLogin  = StartLogin
            , FinishLogin = FinishLogin
         // , Refresh     = Refresh
            ]
         ],
    Label = Extension.LoadString("AuthenticationLabel")
];

SapDataWarehouseCloudConnector.UI = [
    Beta = true,
    dataSourceLabel = Extension.LoadString("FormulaTitle") & " (" & version & ")",
    ButtonText = { dataSourceLabel, Extension.LoadString("FormulaHelp") },
    SourceImage = SapDataWarehouseCloudConnector.Icons,
    SourceTypeImage = SapDataWarehouseCloudConnector.Icons
];

SapDataWarehouseCloudConnector.Icons = [
    Icon16 = { Extension.Contents("dwc16.png"), Extension.Contents("dwc20.png"), Extension.Contents("dwc24.png"), Extension.Contents("dwc32.png") },
    Icon32 = { Extension.Contents("dwc32.png"), Extension.Contents("dwc40.png"), Extension.Contents("dwc48.png"), Extension.Contents("dwc64.png") }
];

StartLogin = (resourceUrl, state, display) =>
    let
        AuthorizeUrl = connections[auth_authorize_url] & "?" & Uri.BuildQueryString([
            client_id = connections[client_id],
            response_type = "code"])
    in
        [
            LoginUri = AuthorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = windowHeight,
            WindowWidth = windowWidth,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) =>
    let
         Parts = Uri.Parts(callbackUri)[Query]
    in
        TokenMethod(Parts[code]);

TokenMethod = (code) =>
    let
         BasicAuth = Binary.ToText(Text.ToBinary(connections[client_id] & ":" & connections[client_secret]),0),
         Response  = Web.Contents(
            connections[auth_token_url], 
            [Content = Text.ToBinary(Uri.BuildQueryString([
                code = code,
                grant_type = "authorization_code",
                response_type = " token"])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json", #"Authorization" = "Basic " & BasicAuth]]),
        Parts = Json.Document(Response)
    in
        Parts;

// receive new access token based on refresh token
 Refresh = (dataSourcePath, refresh_token) => 
    let
        BasicAuth = Binary.ToText(Text.ToBinary(connections[client_id] & ":" & connections[client_secret]),0),
        Response = Web.Contents(connections[auth_token_url], [
            Content = Text.ToBinary(Uri.BuildQueryString([
                refresh_token = refresh_token,
                grant_type = "refresh_token"])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json", #"Authorization" = "Basic " & BasicAuth ]]),
        Parts = Json.Document(Response)
    in
        Parts;
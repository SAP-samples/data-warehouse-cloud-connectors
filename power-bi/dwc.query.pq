// This is where you can write sample queries to test your extension.
let
    //source = SapDataWarehouseCloudConnector.Contents("dwc-field-training.eu10.hcs.cloud.sap","1",null,null,100)
    //source = SapDataWarehouseCloudConnector.Contents("dwc-field-training.eu10.hcs.cloud.sap","1",null,"view*",100)
    //source = SapDataWarehouseCloudConnector.Contents("dwc-field-training.eu10.hcs.cloud.sap","1","INBOUND",null,10)  
    source = SapDataWarehouseCloudConnector.Contents("dwc-field-training.eu10.hcs.cloud.sap","INBOUND","view_PRIVILEGES") 
    //source = SAPDWC_Catalog.Contents("dwc-field-training.eu10.hcs.cloud.sap","INBOUND","") 
    //source = SapDataWarehouseCloudConnector.Contents("dwc-field-training.eu10.hcs.cloud.sap","2","INBOUND",null,100)  
    //source = SapDataWarehouseCloudConnector.Contents("dwc-field-training.eu10.hcs.cloud.sap","2","INBOUND","view_PRIVILEGES",100)  
    //source = SapDataWarehouseCloudConnector.Contents("dwc-field-training.eu10.hcs.cloud.sap","3","sac","t.A.SAP__RT_OAA_IM_SOURCEPRIORITY:SAP__RT_OAA_IM_SOURCEPRIORITY",100)  
    //source = SapAnalyticsCloudConnector.Contents("cpo-sandbox.eu10.sapanalytics.cloud","3","sac","t.1.BestRun_Advanced:BestRun_Advanced",100)  
    //source = SapAnalyticsCloudConnector.Contents("cpo-sandbox.eu10.sapanalytics.cloud","3","sac","C1em3eqnkbiumwj35gmsqpwtts",100)  
    
    // cpo-sandbox.eu10.sapanalytics.cloud
in
    source

    //"search for views", "read data from view"
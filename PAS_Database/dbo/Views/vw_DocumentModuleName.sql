CREATE   VIEW [dbo].[vw_DocumentModuleName]
AS
	SELECT AM.[AttachmentModuleId],
	       AM.[Name],
	       CAST(CASE AM.[Name]
	            WHEN 'WorkOrder'                 THEN 'Work Order'
	            WHEN 'SubWorkOrder'              THEN 'Sub Work Order'
	            WHEN 'WorkOrderQuote'            THEN 'Work Order Quote'
	            WHEN 'WorkOrderTask'             THEN 'Work Order Task'
	            WHEN 'SalesOrder'                THEN 'Sales Order'
	            WHEN 'SalesQuote'                THEN 'Sales Order Quote'
	            WHEN 'SpeedQuote'                THEN 'Speed Quote'
	            WHEN 'PurchaseOrder'             THEN 'Purchase Order'
	            WHEN 'RepairOrder'               THEN 'Repair Order'
	            WHEN 'ExchangeSalesOrder'        THEN 'Exchange Sales Order'
	            WHEN 'ExchangeQuote'             THEN 'Exchange Quote'
	            WHEN 'StockLine'                 THEN 'Stockline'
	            WHEN 'LegalEntity'               THEN 'Legal Entity'
	            WHEN 'VendorRMA'                 THEN 'Vendor RMA'
	            WHEN 'VendorRFQPurchaseOrder'    THEN 'Vendor RFQ Purchase Order'
	            WHEN 'VendorRFQRepairOrder'      THEN 'Vendor RFQ Repair Order'
	            WHEN 'VendorPayment'             THEN 'Vendor Payment'
	            WHEN 'NonPOInvoice'              THEN 'Non-PO Invoice'
	            WHEN 'ReceivingCustomerWork'     THEN 'Receiving Customer Work'
	            WHEN 'ReceivingReconciliation'   THEN 'Receiving Reconciliation'
	            WHEN 'KitMaster'                 THEN 'Kit Master'
	            WHEN 'AircraftRegistry'          THEN 'Aircraft Registry'
	            WHEN 'EngineRegistry'            THEN 'Engine Registry'
	            WHEN 'NhaTlaAltEquItemMapping'   THEN 'NHA/TLA/Alt/Equiv Mapping'
	            ELSE AM.[Name]
	       END AS VARCHAR(100)) AS [ModuleName]
	FROM [dbo].[AttachmentModule] AM WITH (NOLOCK)
	WHERE ISNULL(AM.[IsDeleted], 0) = 0;
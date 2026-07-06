/*************************************************************             
 ** File:   [usprpt_GetCustomerPOFulfillingReport]             
 ** Author:   Amit Ghediya   
 ** Description: Get Data for Customer PO Fulfilling Report   
 ** Purpose:           
 ** Date:   26-Sep-2025         
            
 ** PARAMETERS:             
     
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    26-Sep-2025	  Amit Ghediya	   Created 
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
       
EXECUTE   [dbo].[usprpt_GetCustomerPOFulfillingReport] '2025-10-07','2025-11-25',1,1,'','',2,''
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[usprpt_GetCustomerPOFulfillingReport] 
	@id DATE = NULL,
	@id2 DATE = NULL,
	@mastercompanyid INT,
	@managementStructureId BIGINT,
	@id5 NVARCHAR(200) = '',
	@id3  NVARCHAR(200) = '',
	@id6 VARCHAR(100) = NULL,
	@strFilter VARCHAR(MAX) = NULL
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY 
      
		DECLARE @ModuleId INT = 0,
				@POTypeid varchar(40) = NULL;

		--Po Type
		SET @POTypeid = @id6;

		SELECT @ModuleId = ModuleId FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder'

		IF(@POTypeid = 1)
		BEGIN
			SELECT 
					SO.SalesOrderId,
					SO.CustomerReference AS CustomerPORO,
					SO.CustomerName,
					SO.SalesOrderNumber AS SONum,
					MSOS.[Name] AS SOStatus,
					SOP.POId,
					SOP.PONumber,
					SOP.ConditionName,
					--PO.[Status] AS POStatus,
					CASE 
						WHEN COUNT(DISTINCT ISNULL(NULLIF(PO.[Status], ''), NULL)) 
						   + COUNT(DISTINCT ISNULL(NULLIF(RO.[Status], ''), NULL)) > 1 
							THEN 'Multiple'
						ELSE 
							ISNULL(MAX(PO.[Status]), ISNULL(MAX(RO.[Status]), ''))
					END AS POStatus,
					RO.[Status] AS ROStatus,
					IM.PartNumber AS PN,
					--CASE 
					--	WHEN LEN(IM.PartDescription) > 25 THEN LEFT(IM.PartDescription, 25) + '...'
					--	ELSE IM.PartDescription
					--END AS PNDescription,
					IM.PartDescription AS PNDescription,
					ISNULL(IU.ShortName, '') AS UOM,
					--CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(SST.QtyOrder) ELSE SUM(SOP.QtyOrder) END AS TotalQty,
					--CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN MAX(STKC.NetSaleAmountPerUnit) ELSE SUM(SOPC.NetSaleAmountPerUnit) END AS UnitPrice,
					--CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(SST.QtyOrder * STKC.NetSaleAmountPerUnit) ELSE SUM((SOP.QtyOrder * SOPC.NetSaleAmountPerUnit)) END AS TotalAmount,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SST.QtyOrder ELSE SOP.QtyOrder END AS TotalQty,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN MAX(STKC.NetSaleAmountPerUnit) ELSE SUM(SOPC.NetSaleAmountPerUnit) END AS UnitPrice,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SST.QtyOrder * STKC.NetSaleAmountPerUnit ELSE SOP.QtyOrder * SOPC.NetSaleAmountPerUnit END AS TotalAmount,
					STRING_AGG(STK.StocklineNumber, '') AS StocklineNumbers,
					STK.SerialNumber AS SerialNumbers,
					MAX(BI.InvoiceNo) AS InvoiceNo,
					MAX(SOS.ShipDate) AS ShipDate,
					SO.CreditTermName AS Terms,
					SOS.AirwayBill AS AWB
				FROM [DBO].[SalesOrder] SO WITH(NOLOCK)
				INNER JOIN [DBO].[MasterSalesOrderStatus] MSOS WITH(NOLOCK) ON MSOS.Id = SO.StatusId
				INNER JOIN [DBO].[SalesOrderPartV1] SOP WITH(NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
				LEFT JOIN [DBO].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
				INNER JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
				LEFT JOIN [DBO].[UnitOfMeasure] IU WITH(NOLOCK) ON IM.ConsumeUnitOfMeasureId = IU.UnitOfMeasureId
				LEFT JOIN [DBO].[SalesOrderStocklineV1] SST WITH(NOLOCK) ON SST.SalesOrderPartId = SOP.SalesOrderPartId
				LEFT JOIN [DBO].[Stockline] STK WITH(NOLOCK) ON STK.StockLineId = SST.StockLineId
				LEFT JOIN [DBO].[SalesOrderStockLineCost] STKC WITH(NOLOCK) ON STKC.SalesOrderPartId = SST.SalesOrderPartId AND STKC.SalesOrderStocklineId = SST.SalesOrderStocklineId
				LEFT JOIN [DBO].[BillingInvoicingItems] BII WITH(NOLOCK) ON BII.ReferenceId = SOP.SalesOrderId AND BII.SubReferenceId = SOP.SalesOrderPartId AND BII.ModuleId = @ModuleId AND BII.IsVersionIncrease = 0
				LEFT JOIN [DBO].[BillingInvoicing] BI WITH(NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId
				LEFT JOIN [DBO].[SOPickTicket] SP WITH(NOLOCK) ON SP.SalesOrderPartStocklineId = SST.SalesOrderStocklineId AND SP.SalesOrderPartId = SST.SalesOrderPartId
				LEFT JOIN [DBO].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOSI.SalesOrderPartId = SP.SalesOrderPartId
				LEFT JOIN [DBO].[SalesOrderShipping] SOS WITH(NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				LEFT JOIN [DBO].[RepairOrderPart] ROP WITH(NOLOCK) ON ROP.SalesOrderId = SOP.SalesOrderId AND ROP.StockLineId = SST.StockLineId
				LEFT JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
				LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON PO.PurchaseOrderId = SOP.POId
				WHERE SO.OpenDate >= @id
				  AND SO.OpenDate < DATEADD(DAY, 1, @id2)
				  AND SO.ManagementStructureId = @managementStructureId
				  AND (@id5 = '' OR @id5 IS NULL OR SO.CustomerName LIKE '%' + @id5 + '%')
				  AND (@id3 = '' OR @id3 IS NULL
					   OR SO.CustomerReference LIKE '%' + @id3 + '%'
					   OR SOP.PONumber LIKE '%' + @id3 + '%')
				 AND ISNULL(IM.IsNonStock,0) = 0 GROUP BY 
					SO.SalesOrderId,
					SO.CustomerReference,
					SO.CustomerName,
					SO.SalesOrderNumber,
					MSOS.[Name],
					SOP.POId,
					SOP.PONumber,
					SST.StockLineId,
					SOP.ConditionName,
					PO.[Status],
					RO.[Status],
					IM.PartNumber,
					IM.PartDescription,
					IU.ShortName,
					SST.QtyOrder,
					SOP.QtyOrder,
					STKC.NetSaleAmountPerUnit,
					SOPC.NetSaleAmountPerUnit,
					STK.SerialNumber,
					SO.CreditTermName,
					SOS.AirwayBill
				ORDER BY SO.SalesOrderId DESC;
		END
		ELSE
		BEGIN
			;WITH SalesOrderWithLine AS
			(
				SELECT 
					SO.SalesOrderId,
					SO.CustomerReference AS CustomerPORO,
					SO.CustomerName,
					SO.SalesOrderNumber AS SONum,
					MSOS.[Name] AS SOStatus,
					IM.PartNumber AS PN,
					--CASE 
					--	WHEN LEN(IM.PartDescription) > 25 THEN LEFT(IM.PartDescription, 25) + '...'
					--	ELSE IM.PartDescription
					--END AS PNDescription,
					IM.PartDescription AS PNDescription,
					STK.StockLineId,
					STK.StocklineNumber,
					STK.SerialNumber,
					SOP.ConditionName,
					ISNULL(IU.ShortName, '') AS UOM,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(SST.QtyOrder) ELSE SUM(SOP.QtyOrder) END AS TotalQty,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(STKC.NetSaleAmountPerUnit) ELSE SUM(SOPC.NetSaleAmountPerUnit) END AS UnitPrice,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(SST.QtyOrder * STKC.NetSaleAmountPerUnit) ELSE SUM((SOP.QtyOrder * SOPC.NetSaleAmountPerUnit)) END AS TotalAmount,
					BI.InvoiceNo,
					SOS.ShipDate,
					SO.CreditTermName AS Terms,
					SOS.AirwayBill AS AWB
				FROM [DBO].[SalesOrder] SO WITH(NOLOCK)
				INNER JOIN [DBO].[MasterSalesOrderStatus] MSOS WITH(NOLOCK) ON MSOS.Id = SO.StatusId
				INNER JOIN [DBO].[SalesOrderPartV1] SOP WITH(NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
				LEFT JOIN [DBO].[SalesOrderPartCost] SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
				INNER JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
				LEFT JOIN [DBO].[UnitOfMeasure] IU WITH(NOLOCK) ON IM.ConsumeUnitOfMeasureId = IU.UnitOfMeasureId
				LEFT JOIN [DBO].[SalesOrderStocklineV1] SST WITH(NOLOCK) ON SST.SalesOrderPartId = SOP.SalesOrderPartId
				LEFT JOIN [DBO].[Stockline] STK WITH(NOLOCK) ON STK.StockLineId = SST.StockLineId
				LEFT JOIN [DBO].[SalesOrderStockLineCost] STKC WITH(NOLOCK) ON STKC.SalesOrderPartId = SST.SalesOrderPartId 
				   AND STKC.SalesOrderStocklineId = SST.SalesOrderStocklineId
				LEFT JOIN [DBO].[BillingInvoicingItems] BII WITH(NOLOCK) ON BII.ReferenceId = SOP.SalesOrderId 
				   AND BII.SubReferenceId = SOP.SalesOrderPartId 
				   AND BII.ModuleId = @ModuleId 
				   AND BII.IsVersionIncrease = 0
				LEFT JOIN [DBO].[BillingInvoicing] BI WITH(NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId
				LEFT JOIN [DBO].[SOPickTicket] SP WITH(NOLOCK) ON SP.SalesOrderPartStocklineId = SST.SalesOrderStocklineId 
				   AND SP.SalesOrderPartId = SST.SalesOrderPartId
				LEFT JOIN [DBO].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOSI.SalesOrderPartId = SP.SalesOrderPartId
				LEFT JOIN [DBO].[SalesOrderShipping] SOS WITH(NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
				LEFT JOIN [DBO].[RepairOrderPart] ROP WITH(NOLOCK) ON ROP.SalesOrderId = SOP.SalesOrderId 
				   AND ROP.StockLineId = SST.StockLineId
				WHERE SO.OpenDate >= @id
				  AND SO.OpenDate < DATEADD(DAY, 1, @id2)
				  AND SO.ManagementStructureId = @ManagementStructureId
				  AND (@id5 = '' OR @id5 IS NULL OR SO.CustomerName LIKE '%' + @id5 + '%')  
				  AND (@id3 = '' OR @id3 IS NULL
					   OR SO.CustomerReference LIKE '%' + @id3 + '%'
					   OR SOP.PONumber LIKE '%' + @id3 + '%')
			    AND ISNULL(IM.IsNonStock,0) = 0 GROUP BY 
					SO.SalesOrderId,
					SO.CustomerReference,
					IM.PartNumber,
					IM.PartDescription,
					SO.SalesOrderNumber,
					SO.OpenDate,
					SO.CustomerName,
					SO.CustomerServiceRepName,
					IU.ShortName,
					SOP.ConditionName,
					SO.SalesOrderNumber,
					MSOS.[Name],
					SOP.Notes,
					STK.StockLineId,
					STK.StocklineNumber,
					STK.SerialNumber,
					SST.StockLineId,
					BI.InvoiceNo,
					SOS.ShipDate,
					SO.CreditTermName,
					SOS.AirwayBill
			)
			, AggregatedSales AS
			(
				SELECT 
					SalesOrderId,
					SONum,
					CustomerPORO,
					CustomerName,
					SOStatus,
					COUNT(ConditionName) AS ConditionNameCount,
					STRING_AGG(ConditionName, ', ') AS AllConditionName,
					COUNT(UOM) AS UOMCount,
					STRING_AGG(UOM, ', ') AS AllUOM,
					Terms,
					COUNT(PN) AS PNCount,
					STRING_AGG(PN, ', ') AS AllPNs,
					STRING_AGG(PNDescription, ', ') AS PartDescriptions,
					SUM(TotalQty) AS TotalQty,
					COUNT(UnitPrice) AS UnitPriceCount,
					STRING_AGG(UnitPrice, ', ') AS AllUnitPrice,
					SUM(TotalAmount) AS TotalAmount,
					STRING_AGG(StocklineNumber, ', ') AS StocklineNumbers,
					COUNT(SerialNumber) AS SerialCount,
					COUNT(SerialNumber) AS SerialNumbersCount,
					STRING_AGG(SerialNumber, ', ') AS AllSerialNumbers,
					COUNT(InvoiceNo) AS InvoiceNoCount,
					STRING_AGG(InvoiceNo, ', ') AS AllInvoiceNo,
					COUNT(ShipDate) AS ShipDateCount,
					STRING_AGG(CONVERT(varchar(10), ShipDate, 101), ', ') AS AllShipDate,
					COUNT(AWB) AS AWBCount,
					STRING_AGG(AWB, ', ') AS AllAWB
				FROM SalesOrderWithLine
				GROUP BY SalesOrderId,SONum, CustomerPORO, CustomerName,SOStatus, Terms
			)
			SELECT 
				SalesOrderId,
				SONum,
				CustomerPORO,
				CustomerName,SOStatus,
				CASE WHEN ConditionNameCount > 1 THEN 'MULTIPLE' ELSE AllConditionName END AS ConditionName,
				CASE WHEN UOMCount > 1 THEN 'MULTIPLE' ELSE AllUOM END AS UOM,
				CASE 
					WHEN LEN(CombinedStatusStr) = 0 THEN ''
					WHEN CHARINDEX(',', CombinedStatusStr) > 0 THEN 'MULTIPLE'
					ELSE CombinedStatusStr
				END AS POStatus,
				CASE WHEN PNCount > 1 THEN 'MULTIPLE' ELSE AllPNs END AS PN,
				CASE WHEN PNCount > 1 THEN 'MULTIPLE' ELSE PartDescriptions END AS PNDescription,
				TotalQty,
				TotalAmount,
				CASE WHEN UnitPriceCount > 1 THEN 'MULTIPLE' ELSE AllUnitPrice END AS UnitPrice,
				StocklineNumbers,
				CASE WHEN SerialNumbersCount > 1 THEN 'MULTIPLE' ELSE AllSerialNumbers END AS SerialNumbers,
				CASE WHEN InvoiceNoCount > 1 THEN 'MULTIPLE' ELSE AllInvoiceNo END AS InvoiceNo,
				CASE WHEN ShipDateCount > 1 THEN 'MULTIPLE' ELSE AllShipDate END AS ShipDate,
				Terms,
				CASE WHEN AWBCount > 1 THEN 'MULTIPLE' ELSE AllAWB END AS AWB
			FROM AggregatedSales A
			CROSS APPLY
			(
				SELECT 
				ISNULL(
				  STUFF((
					SELECT ',' + s.Status
					FROM
					(
						SELECT DISTINCT PO.[Status] AS Status
						FROM [DBO].[PurchaseOrder] PO
						INNER JOIN [DBO].[SalesOrderPartV1] SOP ON SOP.POId = PO.PurchaseOrderId
						WHERE SOP.SalesOrderId = A.SalesOrderId AND PO.[Status] IS NOT NULL
						UNION
						SELECT DISTINCT RO.[Status] AS Status
						FROM [DBO].[RepairOrder] RO
						INNER JOIN [DBO].[RepairOrderPart] ROP ON ROP.RepairOrderId = RO.RepairOrderId
						WHERE ROP.SalesOrderId = A.SalesOrderId AND RO.[Status] IS NOT NULL
					) AS s
					FOR XML PATH(''), TYPE
				  ).value('.', 'nvarchar(max)'), 1, 1, '')
				, '') AS CombinedStatusStr
			) CS
			ORDER BY SalesOrderId DESC;
		END
  END TRY    
  BEGIN CATCH  

    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetCapabilitiesReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@id, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@id2, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@id5, '') AS varchar(max)),
            @ApplicationName varchar(100) = 'PAS' 
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH 
  
END
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
       
EXECUTE   [dbo].[usprpt_GetCustomerPOFulfillingReport] '2025-09-26','2025-11-25',1,1,'',''
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[usprpt_GetCustomerPOFulfillingReport] 
	@id DATE = NULL,
	@id2 DATE = NULL,
	@mastercompanyid INT,
	@managementStructureId INT,
	@id4 NVARCHAR(200) = '',
	@id3  NVARCHAR(200) = ''
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY 
      
		--DECLARE @FromDate DATE = '2025-09-26';
		--DECLARE @ToDate   DATE = '2025-11-25';
		--DECLARE @managementStructureId   INT = 1;
		--DECLARE @CustomerName  NVARCHAR(200) = '';
		--DECLARE @POCustRefrence  NVARCHAR(200) = '';
		DECLARE @ModuleId INT = 0;

		SELECT @ModuleId = ModuleId FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder'

		SELECT 
			SO.SalesOrderId,
			SO.CustomerReference AS CustomerPORO,
			SO.CustomerName,
			SO.SalesOrderNumber AS SONum,
			MSOS.[Name] AS SOStatus,
			SOP.POId,
			SOP.PONumber,
			PO.[Status] AS POStatus,
			RO.RepairOrderId,
			RO.RepairOrderNumber,
			RO.[Status] AS ROStatus,
			IM.partnumber AS PN,
			im.PartDescription AS PNDescription,
			--CASE 
			--	WHEN LEN(im.PartDescription) > 25 
			--		THEN LEFT(im.PartDescription, 25) + '...'
			--	ELSE im.PartDescription
			--END AS PNDescription,
			STK.StockLineId,
			STK.StocklineNumber,
			STK.SerialNumber,
			SOP.ConditionName,
			ISNULL(iu.ShortName, '') AS UOM,
			SST.QtyOrder AS Qty,
			STKC.UnitSalesPrice AS UnitPrice,
			(SST.QtyOrder * STKC.UnitSalesPrice) AS Amount,
			BI.InvoiceNo,
			SOS.ShipDate,
			SO.CreditTermName AS Terms,
			SOS.AirwayBill AS AWB,
			SOP.SalesOrderPartId
			FROM [DBO].[SalesOrder] SO WITH(NOLOCK)
			INNER JOIN [DBO].[MasterSalesOrderStatus] MSOS WITH(NOLOCK) ON MSOS.Id = SO.StatusId
			INNER JOIN [DBO].[SalesOrderPartV1] SOP WITH(NOLOCK) ON SOP.SalesOrderId = SO.SalesOrderId
			INNER JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON SOP.ItemMasterId = im.ItemMasterId
			LEFT JOIN [DBO].[UnitOfMeasure] iu WITH(NOLOCK) ON IM.ConsumeUnitOfMeasureId = iu.UnitOfMeasureId
			LEFT JOIN [DBO].[SalesOrderStocklineV1] SST WITH(NOLOCK) ON SST.SalesOrderPartId = SOP.SalesOrderPartId
			LEFT JOIN [DBO].[Stockline] STK WITH(NOLOCK) ON STK.StockLineId = SST.StockLineId
			LEFT JOIN [DBO].[SalesOrderStockLineCost] STKC WITH(NOLOCK) ON STKC.SalesOrderPartId = SST.SalesOrderPartId AND STKC.SalesOrderStocklineId = SSt.SalesOrderStocklineId
			LEFT JOIN [DBO].[BillingInvoicingItems] BII WITH(NOLOCK) ON BII.ReferenceId = SOP.SalesOrderId AND BII.SubReferenceId = SOP.SalesOrderPartId AND BII.ModuleId = @ModuleId AND BII.IsVersionIncrease = 0
			LEFT JOIN [DBO].[BillingInvoicing] BI WITH(NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId AND BII.SubReferenceId = SOP.SalesOrderPartId AND BI.ModuleId = @ModuleId
			LEFT JOIN [DBO].[SOPickTicket] SP WITH(NOLOCK) ON SP.SalesOrderPartStocklineId = SST.SalesOrderStocklineId AND SP.SalesOrderPartId = SST.SalesOrderPartId
			LEFT JOIN [DBO].[SalesOrderShippingItem] SOSI WITH(NOLOCK) ON SOSI.SalesOrderPartId = SP.SalesOrderPartId
			LEFT JOIN [DBO].[SalesOrderShipping] SOS WITH(NOLOCK) ON SOS.SalesOrderShippingId = SOSI.SalesOrderShippingId
			LEFT JOIN [DBO].[RepairOrderPart] ROP WITH(NOLOCK) ON ROP.SalesOrderId = SOP.SalesOrderId AND ROP.StockLineId = SST.StockLineId
			LEFT JOIN [DBO].[RepairOrder] RO WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
			LEFT JOIN [DBO].[PurchaseOrder] PO WITH(NOLOCK) ON PO.PurchaseOrderId = SOP.POId
			WHERE SO.OpenDate >= @id
			  AND SO.OpenDate < DATEADD(DAY, 1, @id2)
			  AND SO.ManagementStructureId = @managementStructureId
			  AND (@id4 = '' OR @id4 IS NULL OR SO.CustomerName LIKE '%' + @id4 + '%')  
			 -- AND SO.CustomerReference LIKE '%' + @POCustRefrence + '%'
			  AND (
				 @id3 = '' OR @id3 IS NULL
				 OR SO.CustomerReference LIKE '%' + @id3 + '%'
				 OR SOP.PONumber LIKE '%' + @id3 + '%'
			   )
			  ORDER BY SO.SalesOrderId DESC;
   
  END TRY  
  
  BEGIN CATCH  

    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetCapabilitiesReport]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@id, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@id2, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@id4, '') AS varchar(max)),
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
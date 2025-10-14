/*************************************************************             
 ** File:   [usprpt_GetCustomerQuoteReport]             
 ** Author:   Amit Ghediya   
 ** Description: Get Data for Customer PO Fulfilling Report   
 ** Purpose:           
 ** Date:   10-10-2025         
            
 ** PARAMETERS:             
     
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    10-10-2025	  Amit Ghediya	   Created 
       
EXECUTE   [dbo].[usprpt_GetCustomerQuoteReport] '2025-10-07','2025-11-25',1,1,'','',2,''
**************************************************************/  
  
CREATE     PROCEDURE [dbo].[usprpt_GetCustomerQuoteReport] 
	@id DATE = NULL,
	@id2 DATE = NULL,
	@mastercompanyid INT,
	@managementStructureId BIGINT,
	@id5 NVARCHAR(200) = '',
	@id3  NVARCHAR(200) = '',
	@id6 VARCHAR(100) = NULL,
	@strFilter VARCHAR(MAX) = NULL,
	@id7 VARCHAR(100) = NULL
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY 
      
		DECLARE @ModuleId INT = 0,
				@POTypeid varchar(40) = NULL,
				@SalesOrderQuoteId BIGINT,
				@CustomerId BIGINT,
				@ItemMasterId BIGINT;

		--Po Type
		SET @POTypeid = @id6;

		SET @SalesOrderQuoteId = case when @id3 = '' OR @id3 = '0' then null else @id3 end;
		SET @CustomerId = case when @id5 = '' OR @id5 = '0' then null else @id5 end;
		SET @ItemMasterId = case when @id7 = '' OR @id7 = '0' then null else @id7 end;

		SELECT @ModuleId = ModuleId FROM Module WHERE ModuleName = 'SalesQuote';

		IF(@POTypeid = 1)
		BEGIN
			SELECT 
				SOQ.SalesOrderQuoteId,
				IM.PartNumber AS PN,
				--CASE 
				--	WHEN LEN(IM.PartDescription) > 25 THEN LEFT(IM.PartDescription, 25) + '...'
				--	ELSE IM.PartDescription
				--END AS PNDescription,
				IM.PartDescription AS PNDescription,
				SOQ.SalesOrderQuoteNumber AS SOQNum,
				SOQ.OpenDate AS QuoteDate,
				SOQ.CustomerName,
				SOQ.LeadSourceName AS Source,
				SOQ.CustomerServiceRepName AS SourceRef,
				ISNULL(IU.ShortName, '') AS UOM,
				SOP.ConditionName AS Cond,				
				--CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(SST.QtyQuoted) ELSE SUM(SOP.QtyRequested) END AS TotalQty,
				--CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN MAX(STKC.NetSaleAmountPerUnit) ELSE SUM(SOPC.NetSaleAmountPerUnit) END AS UnitPrice,
				--CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(SST.QtyQuoted * STKC.NetSaleAmountPerUnit) ELSE SUM((SOP.QtyRequested * SOPC.NetSaleAmountPerUnit)) END AS TotalAmount,
				CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SST.QtyQuoted ELSE SOP.QtyRequested END AS TotalQty,
				CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN MAX(STKC.NetSaleAmountPerUnit) ELSE SUM(SOPC.NetSaleAmountPerUnit) END AS UnitPrice,
				CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SST.QtyQuoted * STKC.NetSaleAmountPerUnit ELSE SOP.QtyRequested * SOPC.NetSaleAmountPerUnit END AS TotalAmount,
				SO.SalesOrderNumber AS SONum,
				MSOS.[Name] AS SOStatus,
				MAX(SOVS.ShipDate) AS ShipDate,
				SOQ.CreditTermName AS Terms,
				SOVS.AirwayBill AS AWB,
				SOP.Notes
			FROM [DBO].[SalesOrderQuote] SOQ WITH(NOLOCK)
			INNER JOIN [DBO].[SalesOrderQuotePartV1] SOP WITH(NOLOCK) ON SOP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
			LEFT JOIN [DBO].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK) ON SOPC.SalesOrderQuotePartId = SOP.SalesOrderQuotePartId
			INNER JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
			LEFT JOIN [DBO].[UnitOfMeasure] IU WITH(NOLOCK) ON IM.ConsumeUnitOfMeasureId = IU.UnitOfMeasureId
			LEFT JOIN [DBO].[SalesOrderQuoteStocklineV1] SST WITH(NOLOCK) ON SST.SalesOrderQuotePartId = SOP.SalesOrderQuotePartId
			LEFT JOIN [DBO].[SalesOrderQuoteStockLineCost] STKC WITH(NOLOCK) ON STKC.SalesOrderQuotePartId = SST.SalesOrderQuotePartId AND STKC.SalesOrderQuoteStocklineId = SST.SalesOrderQuoteStocklineId
			LEFT JOIN [DBO].[BillingInvoicingItems] BII WITH(NOLOCK) ON BII.ReferenceId = SOP.SalesOrderQuoteId AND BII.SubReferenceId = SOP.SalesOrderQuotePartId AND BII.ModuleId = @ModuleId AND BII.IsVersionIncrease = 0
			LEFT JOIN [DBO].[BillingInvoicing] BI WITH(NOLOCK) ON BII.BillingInvoicingId = BI.BillingInvoicingId
			LEFT JOIN [DBO].[SalesOrder] SO WITH(NOLOCK) ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
			LEFT JOIN [DBO].[SalesOrderPartV1] SOVP WITH(NOLOCK) ON SOVP.SalesOrderId = SO.SalesOrderId
			LEFT JOIN [DBO].[SalesOrderStocklineV1] SSVT WITH(NOLOCK) ON SSVT.SalesOrderPartId = SOVP.SalesOrderPartId
			LEFT JOIN [DBO].[SOPickTicket] SVP WITH(NOLOCK) ON SVP.SalesOrderPartStocklineId = SSVT.SalesOrderStocklineId AND SVP.SalesOrderPartId = SSVT.SalesOrderPartId
			LEFT JOIN [DBO].[SalesOrderShippingItem] SOSVI WITH(NOLOCK) ON SOSVI.SalesOrderPartId = SVP.SalesOrderPartId
			LEFT JOIN [DBO].[SalesOrderShipping] SOVS WITH(NOLOCK) ON SOVS.SalesOrderShippingId = SOSVI.SalesOrderShippingId
			LEFT JOIN [DBO].[MasterSalesOrderStatus] MSOS WITH(NOLOCK) ON MSOS.Id = SO.StatusId
			WHERE SOQ.SalesOrderQuoteId = ISNULL(@SalesOrderQuoteId,SOQ.SalesOrderQuoteId)
			  AND	SOQ.OpenDate >= @id
			  AND SOQ.OpenDate < DATEADD(DAY, 1, @id2)
			  AND SOQ.ManagementStructureId = @managementStructureId
			  AND SOQ.CustomerId = ISNULL(@CustomerId,SOQ.CustomerId)
			  AND SOP.ItemMasterId = ISNULL(@ItemMasterId,SOP.ItemMasterId)
			GROUP BY 
				SOQ.SalesOrderQuoteId,
				IM.PartNumber,
				IM.PartDescription,
				SOQ.SalesOrderQuoteNumber,
				SOQ.OpenDate,
				SOQ.CustomerName,
				SOQ.LeadSourceName,
				SOQ.CustomerServiceRepName,
				SOP.ConditionName,
				SOP.QtyRequested,
				MSOS.[Name],
				IU.ShortName,
				SST.QtyQuoted,
				SOP.QtyRequested,
				STKC.NetSaleAmountPerUnit,
				SOPC.NetSaleAmountPerUnit,
				SOQ.CreditTermName,
				SO.SalesOrderNumber,
				SOVS.AirwayBill,
				SOP.Notes,
				SST.StockLineId
			ORDER BY SOQ.SalesOrderQuoteId DESC;
		END
		ELSE
		BEGIN
			;WITH SalesOrderWithLine AS
			(
				SELECT 
					SOQ.SalesOrderQuoteId,
					IM.PartNumber AS PN,
					--CASE 
					--	WHEN LEN(IM.PartDescription) > 25 THEN LEFT(IM.PartDescription, 25) + '...'
					--	ELSE IM.PartDescription
					--END AS PNDescription,
					IM.PartDescription AS PNDescription,
					SOQ.SalesOrderQuoteNumber AS SOQNum,
					SOQ.OpenDate AS QuoteDate,
					SOQ.CustomerName,
					SOQ.LeadSourceName AS Source,
					SOQ.CustomerServiceRepName AS SourceRef,
					ISNULL(IU.ShortName, '') AS UOM,
					SOP.ConditionName AS Cond,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(SST.QtyQuoted) ELSE SUM(SOP.QtyRequested) END AS TotalQty,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(STKC.NetSaleAmountPerUnit) ELSE SUM(SOPC.NetSaleAmountPerUnit) END AS UnitPrice,
					CASE WHEN ISNULL(SST.StockLineId,0) > 0 THEN SUM(SST.QtyQuoted * STKC.NetSaleAmountPerUnit) ELSE SUM((SOP.QtyRequested * SOPC.NetSaleAmountPerUnit)) END AS TotalAmount,
					SO.SalesOrderNumber AS SONum,
					MSOS.[Name] AS SOStatus,
					SOQ.CreditTermName AS Terms,
					SOVS.ShipDate,
					SOVS.AirwayBill AS AWB,
					SOP.Notes
				FROM [DBO].[SalesOrderQuote] SOQ WITH(NOLOCK)
				INNER JOIN [DBO].[SalesOrderQuotePartV1] SOP WITH(NOLOCK) ON SOP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
				LEFT JOIN [DBO].[SalesOrderQuotePartCost] SOPC WITH(NOLOCK) ON SOPC.SalesOrderQuotePartId = SOP.SalesOrderQuotePartId
				INNER JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
				LEFT JOIN [DBO].[UnitOfMeasure] IU WITH(NOLOCK) ON IM.ConsumeUnitOfMeasureId = IU.UnitOfMeasureId
				LEFT JOIN [DBO].[SalesOrderQuoteStocklineV1] SST WITH(NOLOCK) ON SST.SalesOrderQuotePartId = SOP.SalesOrderQuotePartId
				LEFT JOIN [DBO].[SalesOrderQuoteStockLineCost] STKC WITH(NOLOCK) ON STKC.SalesOrderQuotePartId = SST.SalesOrderQuotePartId 
					AND STKC.SalesOrderQuoteStocklineId = SST.SalesOrderQuoteStocklineId
				LEFT JOIN [DBO].[SalesOrder] SO WITH(NOLOCK) ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
				LEFT JOIN [DBO].[SalesOrderPartV1] SOVP WITH(NOLOCK) ON SOVP.SalesOrderId = SO.SalesOrderId
				LEFT JOIN [DBO].[SalesOrderStocklineV1] SSVT WITH(NOLOCK) ON SSVT.SalesOrderPartId = SOVP.SalesOrderPartId
				LEFT JOIN [DBO].[SOPickTicket] SVP WITH(NOLOCK) ON SVP.SalesOrderPartStocklineId = SSVT.SalesOrderStocklineId 
					AND SVP.SalesOrderPartId = SSVT.SalesOrderPartId
				LEFT JOIN [DBO].[SalesOrderShippingItem] SOSVI WITH(NOLOCK) ON SOSVI.SalesOrderPartId = SVP.SalesOrderPartId
				LEFT JOIN [DBO].[SalesOrderShipping] SOVS WITH(NOLOCK) ON SOVS.SalesOrderShippingId = SOSVI.SalesOrderShippingId
				LEFT JOIN [DBO].[MasterSalesOrderStatus] MSOS WITH(NOLOCK) ON MSOS.Id = SO.StatusId
			WHERE SOQ.SalesOrderQuoteId = ISNULL(@SalesOrderQuoteId,SOQ.SalesOrderQuoteId)
			  AND	SOQ.OpenDate >= @id
			  AND SOQ.OpenDate < DATEADD(DAY, 1, @id2)
			  AND SOQ.ManagementStructureId = @managementStructureId
			  AND SOQ.CustomerId = ISNULL(@CustomerId,SOQ.CustomerId)
			  AND SOP.ItemMasterId = ISNULL(@ItemMasterId,SOP.ItemMasterId)
			  GROUP BY 
				SOQ.SalesOrderQuoteId,
				IM.PartNumber,
				IM.PartDescription,
				SOQ.SalesOrderQuoteNumber,
				SOQ.OpenDate,
				SOQ.CustomerName,
				SOQ.LeadSourceName,
				SOQ.CustomerServiceRepName,
				IU.ShortName,
				SOP.ConditionName,
				SO.SalesOrderNumber,
				MSOS.[Name],
				SOQ.CreditTermName,
				SOVS.ShipDate,
				SOVS.AirwayBill,
				SOP.Notes,
				SST.StockLineId
			),
			AggregatedSales AS
			(
				SELECT 
					SalesOrderQuoteId,
					SOQNum,
					SONum,
					QuoteDate,
					CustomerName,
					COUNT(Source) AS SourceCount,
					STRING_AGG(Source, ', ') AS AllSource,
					COUNT(SourceRef) AS SourceRefCount,
					STRING_AGG(SourceRef, ', ') AS AllSourceRef,
					UOM,
					SOStatus,
					Terms,
					COUNT(Cond) AS CondCount,
					STRING_AGG(Cond, ', ') AS AllCond,
					COUNT(PN) AS PNCount,
					STRING_AGG(PN, ', ') AS AllPNs,
					STRING_AGG(PNDescription, ', ') AS PartDescriptions,
					SUM(TotalQty) AS TotalQty,
					COUNT(UnitPrice) AS UnitPriceCount,
					STRING_AGG(UnitPrice, ', ') AS AllUnitPrice,
					SUM(TotalAmount) AS TotalAmount,
					MAX(ShipDate) AS ShipDate,
					COUNT(AWB) AS AWBCount,
					STRING_AGG(AWB, ', ') AS AllAWB,
					STRING_AGG(Notes, ', ') AS Notes
				FROM SalesOrderWithLine
				GROUP BY SalesOrderQuoteId, SOQNum,SONum,QuoteDate,
				UOM, CustomerName, SOStatus, Terms
			)
			SELECT 
				SalesOrderQuoteId,
				CASE WHEN PNCount > 1 THEN 'MULTIPLE' ELSE AllPNs END AS PN,
				CASE WHEN PNCount > 1 THEN 'MULTIPLE' ELSE PartDescriptions END AS PNDescription,
				SOQNum,
				QuoteDate,
				CustomerName,
				CASE WHEN SourceCount > 1 THEN 'MULTIPLE' ELSE AllSource END AS Source,
				CASE WHEN SourceRefCount > 1 THEN 'MULTIPLE' ELSE AllSourceRef END AS SourceRef,
				UOM,
				CASE WHEN CondCount > 1 THEN 'MULTIPLE' ELSE AllCond END AS Cond,
				TotalQty,
				CASE WHEN UnitPriceCount > 1 THEN 'MULTIPLE' ELSE AllUnitPrice END AS UnitPrice,
				TotalAmount,
				SONum,
				SOStatus,
				ShipDate,
				Terms,
				CASE WHEN AWBCount > 1 THEN 'MULTIPLE' ELSE AllAWB END AS AWB,
				Notes
			FROM AggregatedSales
			ORDER BY SalesOrderQuoteId DESC;
		END
  END TRY    
  BEGIN CATCH  

    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[usprpt_GetCustomerQuoteReport]',  
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
/*************************************************************           
 ** File:		 [USP_GetNonStockItemDataByID]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get NonStock Item Master Data By Id.
 ** Purpose:         
 ** Date:   29-September-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date					Author				Change Description            
 ** --   -----------------		----------------	--------------------------------          
    1    29-September-2025 		Divyesh Kathiriya	Created	
    
 -- EXEC [USP_GetNonStockItemDataByID] @ItemMasterId=34
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetNonStockItemDataByID]
@ItemMasterId BIGINT = Null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		SELECT TOP 1
		   iM.[ItemMasterNonStockId],
		   iM.[MasterPartId],
		   iM.[PartNumber],
		   iM.[ItemTypeId],
		   iM.[PartDescription],
		   iM.[ItemGroupId],
		   iM.[ItemNonStockClassificationId],
		   iM.[ManufacturerId],
		   iM.[GLAccountId],
		   gl.[AccountCode] + ' - ' + gl.[AccountName] AS [glAccount],
		   iM.[IsHazardousMaterial],
		   imCls.[Description] AS [ItemNonStockClassification],
		   itg.[Description] AS [itemGroup],
		   ISNULL(mfgs.[Name], '') AS [ManufacturerName],
		   iM.[PurchaseUnitOfMeasureId],
		   ipuom.[ShortName] AS [purchaseUnitOfMeasure],
		   iM.[PriceDate],
		   iM.[ListPrice],
		   iM.[UnitCost],
		   ISNULL(disc.[DiscontValue], 0) AS [DiscountPurchasePercent],
		   iM.[IsAcquiredMethodBuy],
		   iM.[CurrencyId],
		   ISNULL(cucy.[Code], '') AS [CurrencyName],
		   iM.[SiteId],
		   iM.[WarehouseId],
		   iM.[ShelfId],
		   iM.[LocationId],
		   iM.[BinId],
		   iM.[IsSerialized],
		   iM.[IsMfgExpirationDate],
		   iM.[LeadTimeDays],
		   iM.[StockLevel],
		   iM.[ReorderPoint],
		   iM.[ReorderQuantiy],
		   iM.[InWarranty],
		   iM.[Site],
		   iM.[Warehouse],
		   iM.[Location],
		   iM.[Shelf],
		   iM.[Bin],
		   iM.[MfgExpirationDate]
		FROM [DBO].[ItemMasterNonStock] iM WITH(NOLOCK)
		LEFT JOIN [DBO].[ItemMasterIntegrationPortal] iPortal WITH(NOLOCK) ON iM.[ItemMasterNonStockId] = iPortal.[ItemMasterId]
		LEFT JOIN [DBO].[Manufacturer] mfgs WITH(NOLOCK) ON iM.[ManufacturerId] = mfgs.[ManufacturerId]
		LEFT JOIN [DBO].[ItemClassification] imCls WITH(NOLOCK) ON iM.[ItemNonStockClassificationId] = imCls.[ItemClassificationId]
		LEFT JOIN [DBO].[ItemGroup] itg WITH(NOLOCK) ON iM.[ItemGroupId] = itg.[ItemGroupId]
		LEFT JOIN [DBO].[GLAccount] gl WITH(NOLOCK) ON iM.[GLAccountId] = gl.[GLAccountId]
		LEFT JOIN [DBO].[Currency] cucy WITH(NOLOCK) ON iM.[CurrencyId] = cucy.[CurrencyId]
		LEFT JOIN [DBO].[Discount] disc WITH(NOLOCK) ON CAST(iM.[DiscountPurchasePercent] AS BIGINT) = disc.[DiscountId]
		LEFT JOIN [DBO].[UnitOfMeasure] ipuom WITH(NOLOCK) ON iM.[PurchaseUnitOfMeasureId] = ipuom.[UnitOfMeasureId]
		WHERE iM.[ItemMasterNonStockId] = @ItemMasterId;

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetNonStockItemDataByID'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END
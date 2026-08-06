/*************************************************************           
 ** File:		 [USP_GetNonStockDataByPartID]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get NonStockd ItemMaster Data By PartID.
 ** Purpose:         
 ** Date:   25-DEC-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    25-DEC-2025		Divyesh Kathiriya	Created
    2	15/July/2026		RAJESH GAMI			[PN-17271] - Fixed: this SP was still querying the legacy
    3	23/July/2026		RAJESH GAMI			[PN-17350] - Fixed wrong currency: ItemMaster has a legacy,
    
 -- EXEC [USP_GetNonStockDataByPartID] @ItemMasterId=181
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetNonStockDataByPartID]
@ItemMasterId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	
		SELECT TOP 1
            [im].[ItemMasterId] AS [ItemMasterNonStockId],
            [im].[PartNumber],
            [im].[ItemTypeId],
            [im].[PartDescription],
            [im].[ManufacturerId],
            [im].[GLAccountId],
            [gl].[AccountName] AS [GlAccount],
            ISNULL([mfg].[Name], '') AS [ManufacturerName],
            [im].[PurchaseUnitOfMeasureId],
            [ipuom].[ShortName] AS [PurchaseUnitOfMeasure],
            [im].[PriceDate],
            [im].[ListPrice],
            [im].[UnitCost],
            [im].[DiscountPurchasePercent],
            [im].[CurrencyId],
            ISNULL([cucy].[Code], '') AS [CurrencyName]
        FROM[DBO].[ItemMaster] AS [im] WITH(NOLOCK)
        LEFT JOIN[DBO].[Manufacturer] AS [mfg] WITH(NOLOCK) ON [im].[ManufacturerId] = [mfg].[ManufacturerId]
        LEFT JOIN[DBO].[GLAccount] AS [gl] WITH(NOLOCK) ON [im].[GLAccountId] = [gl].[GLAccountId]
        LEFT JOIN[DBO].[Currency] AS [cucy] WITH(NOLOCK) ON [im].[CurrencyId] = [cucy].[CurrencyId]
        LEFT JOIN[DBO].[UnitOfMeasure] AS [ipuom] WITH(NOLOCK) ON [im].[PurchaseUnitOfMeasureId] = [ipuom].[UnitOfMeasureId]
        WHERE [im].[MasterPartId] = @ItemMasterId;			  		 	   			   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetNonStockDataByPartID'
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
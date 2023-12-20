/*************************************************************           
 ** File:   [GetReceiverStockRMAPNLabel]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Get Vendor RMA STOCKLINE Details
 ** Date:   07/06/2023
 ** PARAMETERS: @VendorRMAId BIGINT          
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    07/06/2023   Moin Bloch     Created
*******************************************************************************
EXEC GetReceiverStockRMAPNLabel 113,1,1,1,''
*******************************************************************************/
CREATE   PROCEDURE [dbo].[GetReceiverStockRMAPNLabel]
@VendorRMAId BIGINT,
@IsParent VARCHAR(10),
@ReceiverNumber VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		IF(@IsParent = '1')
		BEGIN
			SELECT SL.[ReceiverNumber],CAST(SL.[ReceivedDate] AS DATE) AS [ReceivedDate] FROM [dbo].[Stockline] SL WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = SL.[ItemMasterId]
			WHERE [VendorRMAId] = @VendorRMAId AND [IsParent] = 1
			GROUP BY SL.[ReceiverNumber],CAST(SL.[ReceivedDate] AS DATE)
		END
		IF(@IsParent = '0')
		BEGIN
			SELECT SL.[StockLineId],
				   IM.[partnumber],
				   IM.[PartDescription],
				   SL.[Condition],
				   SL.[UnitOfMeasure],			       
				   SL.[StockLineNumber],
				   SL.[SerialNumber],				  
				   SL.[Quantity] AS Qty,	
				   SL.[ControlNumber],
				   SL.[IdNumber],
				   SL.[ReceiverNumber],
				   CAST(SL.[ReceivedDate] AS DATE) AS [ReceivedDate],
			       SI.[Name] AS 'SiteName',
				   WH.[Name] AS 'WareHouseName',
				   BN.[Name] AS 'BinName',
				   SF.[Name] AS 'ShelfName',
				   LC.[Name] AS 'LocationName',
				   1 AS Modules,
				   'STOCK' AS [ModuleName],				
				   '' AS [ReferenceNumber],
				   SL.[Manufacturer],				  
				   CAST(SL.ExpirationDate AS DATE) AS [ExpirationDate],
				   SL.[TraceableToName]
			    FROM [dbo].[Stockline] SL WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
			INNER JOIN [dbo].[StocklineDraft] SD WITH(NOLOCK) ON SL.StockLineId = sd.StockLineId			
			LEFT JOIN  [dbo].[Site] SI WITH(NOLOCK) ON SI.SiteId = SL.SiteId
			LEFT JOIN  [dbo].[Warehouse] WH WITH(NOLOCK) ON WH.WarehouseId = SL.WarehouseId
			LEFT JOIN  [dbo].[Bin] BN WITH(NOLOCK) ON BN.BinId = SL.BinId
			LEFT JOIN  [dbo].[Shelf] SF WITH(NOLOCK) ON SF.ShelfId = SL.ShelfId
			LEFT JOIN  [dbo].[Location] LC WITH(NOLOCK) ON LC.LocationId = SL.LocationId
			WHERE SL.[VendorRMAId] = @VendorRMAId AND SL.[ReceiverNumber] = @ReceiverNumber AND SL.[IsParent] = 1;			
		END	
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'			
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceiverStockRMAPNLabel' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',
													 @Parameter2 = ' + ISNULL(@IsParent,'') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END
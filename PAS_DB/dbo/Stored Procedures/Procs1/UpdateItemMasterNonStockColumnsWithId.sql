/*************************************************************           
 ** File:   [UpdateItemMasterNonStockColumnsWithId]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Update Non Stockline Details based on Stockline Id.    
 ** Purpose:         
 ** Date:    02/04/2020       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/04/2020   Subhash Saliya Created

     
--  EXEC [UpdateItemMasterNonStockColumnsWithId] 1
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateItemMasterNonStockColumnsWithId]
	@ItemMasterNonStockId int
AS
BEGIN
	SET NOCOUNT ON;


	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				UPDATE SL SET 
					SL.GLAccount = GL.AccountName,
					SL.Manufacturer = MF.Name,
					SL.Site = S.Name,
					SL.Warehouse = W.Name,
					SL.Location = L.Name,
					SL.Shelf = SF.Name,
					SL.Bin = B.Name,
					SL.Currency = cr.DisplayName,
					SL.ItemNonStockClassification=IC.Description
					
				
				FROM [dbo].[ItemMasterNonStock] SL WITH(NOLOCK)
					INNER JOIN dbo.Manufacturer MF WITH(NOLOCK) ON SL.ManufacturerId = MF.ManufacturerId
					INNER JOIN dbo.Site S WITH(NOLOCK) ON S.SiteId = SL.SiteId
					LEFT JOIN dbo.GLAccount GL WITH(NOLOCK) ON SL.GLAccountId = GL.GLAccountId 
					LEFT JOIN dbo.Warehouse W WITH(NOLOCK) ON W.WarehouseId = SL.WarehouseId
					LEFT JOIN dbo.Location L WITH(NOLOCK) ON L.LocationId = SL.LocationId
					LEFT JOIN dbo.Shelf SF WITH(NOLOCK) ON SF.ShelfId = SL.ShelfId
					LEFT JOIN dbo.Bin B WITH(NOLOCK) ON B.BinId = SL.BinId
					LEFT JOIN dbo.Currency cr WITH(NOLOCK) ON SL.CurrencyId = cr.CurrencyId
				    LEFT JOIN dbo.ItemClassification IC WITH(NOLOCK) ON SL.ItemNonStockClassificationId = IC.ItemClassificationId
				WHERE SL.ItemMasterNonStockId = @ItemMasterNonStockId

			
			END		   
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateItemMasterNonStockColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterNonStockId, '') + ''
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
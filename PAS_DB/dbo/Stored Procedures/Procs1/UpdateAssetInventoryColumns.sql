
/*************************************************************           
 ** File:   [UpdateAssetInventoryColumns]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used UpdateAssetInventoryColumns.    
 ** Purpose:         
 ** Date:   04/21/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/30/2020   Subhash Saliya Created
	2    07/06/2021   Hemant Saliya  Updated Where Conditions
	2    03/16/2022   Vishal Suthar  Added Site, Warehouse, Location, Shelf and Bin
     
--EXEC [UpdateAssetInventoryColumns] 85
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateAssetInventoryColumns]
	@AssetInventoryId int
AS
BEGIN
	   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	   SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
			    Update AI SET 					
					AI.LocationName = Lo.Name,
					AI.ManufactureName = MF.Name,
					AI.SiteName = st.Name,
					AI.Warehouse = wh.Name,
					AI.Location = Loc.Name,
					AI.ShelfName = shelf.Name,
					AI.BinName = bin.Name
			    FROM [dbo].[AssetInventory] AI WITH (NOLOCK)
					LEFT JOIN dbo.Manufacturer MF WITH (NOLOCK) ON AI.ManufacturerId = MF.ManufacturerId
					LEFT JOIN dbo.Site st WITH (NOLOCK) ON AI.SiteId = st.SiteId
					LEFT JOIN dbo.Warehouse wh WITH (NOLOCK) ON AI.WarehouseId = wh.WarehouseId
					LEFT JOIN dbo.[Location] Lo WITH (NOLOCK) ON AI.AssetLocationId = Lo.LocationId
					LEFT JOIN dbo.[Location] Loc WITH (NOLOCK) ON AI.LocationId = Loc.LocationId
					LEFT JOIN dbo.Shelf shelf WITH (NOLOCK) ON AI.ShelfId = shelf.ShelfId
					LEFT JOIN dbo.Bin bin WITH (NOLOCK) ON AI.BinId = bin.BinId
				WHERE AI.AssetInventoryId = @AssetInventoryId
		END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateAssetInventoryColumns' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetInventoryId, '') + ''
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

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
     
--EXEC [UpdateAssetInventoryColumns] 624
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
				DECLARE @ManagmnetStructureId as BIGINT
				DECLARE @Level1 as varchar(200)
				DECLARE @Level2 as varchar(200)
				DECLARE @Level3 as varchar(200)
				DECLARE @Level4 as varchar(200)

	            SELECT @ManagmnetStructureId = ManagementStructureId FROM [dbo].[AssetInventory] WITH (NOLOCK) WHERE AssetInventoryId = @AssetInventoryId

				EXEC dbo.GetMSNameandCode @ManagmnetStructureId,
				 @Level1 = @Level1 OUTPUT,
				 @Level2 = @Level2 OUTPUT,
				 @Level3 = @Level3 OUTPUT,
				 @Level4 = @Level4 OUTPUT

			    Update AI SET 
					AI.Level1 = @Level1,
					AI.Level2 = @Level2,
					AI.Level3 = @Level3,
					AI.Level4 = @Level4,
					AI.LocationName = Lo.Name,
					AI.ManufactureName = MF.Name
			    FROM [dbo].[AssetInventory] AI WITH (NOLOCK)
					LEFT JOIN dbo.Manufacturer MF WITH (NOLOCK) ON AI.ManufacturerId = MF.ManufacturerId
					LEFT JOIN dbo.[Location] Lo WITH (NOLOCK) ON AI.AssetLocationId = Lo.LocationId
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
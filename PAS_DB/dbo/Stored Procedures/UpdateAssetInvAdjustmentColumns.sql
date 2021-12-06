
/*************************************************************           
 ** File:   [UpdateStocklineColumnsWithId]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Update AssetInvAdjustmentColumns.    
 ** Purpose:         
 ** Date:    05/07/2021       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/07/2021   Subhash Saliya Created
     
--EXEC [UpdateStocklineColumnsWithId] 624
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateAssetInvAdjustmentColumns]
	@AssetInventoryAdjustmentId bigint,
	@AdjustmentDataTypeId int
AS
BEGIN
	
	   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	   SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					DECLARE @ManagmnetStructureId as bigInt
					DECLARE @ManagmnetStructureId1 as bigInt
					DECLARE @Level1 as varchar(200)
					DECLARE @Level2 as varchar(200)
					DECLARE @Level3 as varchar(200)
					DECLARE @Level4 as varchar(200)
					DECLARE @Level11 as varchar(200)
					DECLARE @Level21 as varchar(200)
					DECLARE @Level31 as varchar(200)
					DECLARE @Level41 as varchar(200)

					IF(@AdjustmentDataTypeId =1)
					BEGIN
						 SELECT @ManagmnetStructureId = ISNULL(ChangedTo, 0), @ManagmnetStructureId1 = ISNULL(ChangedFrom, 0) FROM [dbo].[AssetInventoryAdjustment] WITH (NOLOCK) where AssetInventoryAdjustmentId = @AssetInventoryAdjustmentId and AssetInventoryAdjustmentDataTypeId = @AdjustmentDataTypeId
					 
						 EXEC dbo.GetMSNameandCode @ManagmnetStructureId,
						 @Level1 = @Level1 OUTPUT,
						 @Level2 = @Level2 OUTPUT,
						 @Level3 = @Level3 OUTPUT,
						 @Level4 = @Level4 OUTPUT

						 UPDATE dbo.[AssetInventoryAdjustment] set ChangedTo = @Level1 FROM [dbo].[AssetInventoryAdjustment] where AssetInventoryAdjustmentId = @AssetInventoryAdjustmentId and AssetInventoryAdjustmentDataTypeId = @AdjustmentDataTypeId
						  
						 EXEC dbo.GetMSNameandCode @ManagmnetStructureId1,
						 @Level1 = @Level1 OUTPUT,
						 @Level2 = @Level2 OUTPUT,
						 @Level3 = @Level3 OUTPUT,
						 @Level4 = @Level4 OUTPUT

						 UPDATE dbo.AssetInventoryAdjustment set ChangedFrom = @Level1 FROM [dbo].AssetInventoryAdjustment where AssetInventoryAdjustmentId=@AssetInventoryAdjustmentId and AssetInventoryAdjustmentDataTypeId = @AdjustmentDataTypeId
					END
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateAssetInvAdjustmentColumns' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetInventoryAdjustmentId, '') + ''',
			                                           @Parameter2 = ' + ISNULL(@AdjustmentDataTypeId ,'') +''
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

/*************************************************************           
 ** File:   [WOSummarizedHistory]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Update Asset ID Columns.    
 ** Purpose:      
 ** Date:   07/06/2021        
          
 ** PARAMETERS:           
 @AssetRecordId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/06/2021   Hemant Saliya Created
     
--EXEC [WOSummarizedHistory] 624
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateAssetColumns]
@AssetRecordId int
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

					SELECT @ManagmnetStructureId = ManagementStructureId FROM [dbo].[Asset] WITH (NOLOCK) WHERE AssetRecordId = @AssetRecordId

					EXEC dbo.GetMSNameandCode @ManagmnetStructureId,
					 @Level1 = @Level1 OUTPUT,
					 @Level2 = @Level2 OUTPUT,
					 @Level3 = @Level3 OUTPUT,
					 @Level4 = @Level4 OUTPUT

					Update A SET 
						A.Level1 = @Level1,
						A.Level2 = @Level2,
						A.Level3 = @Level3,
						A.Level4 = @Level4				
					FROM [dbo].[Asset] A WITH (NOLOCK)
					WHERE A.AssetRecordId = @AssetRecordId
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateAssetColumns' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AssetRecordId, '') + ''
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
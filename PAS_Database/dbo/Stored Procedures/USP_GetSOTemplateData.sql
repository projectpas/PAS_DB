/*************************************************************           
 ** File:   [dbo].[USP_GetSOTemplateData]          
 ** Author:   Amit Ghediya
 ** Description: Get SO Template Data.
 ** Date:   07-05-2025   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------			--------------------------------          
	1    07-05-2025		Amit Ghediya	    Created

** EXEC [dbo].[USP_GetSOTemplateData] 102536,223
**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetSOTemplateData]
	@ItemId BIGINT,
	@WorkPerformId BIGINT,
	@MasterCompanyID BIGINT = NULL 
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
			
			IF(ISNULL(@ItemId,0) > 0 AND ISNULL(@WorkPerformId,0) > 0)
			BEGIN
				SELECT 
				[RepairOrderTemplateId],
				[RepairOrderTemplateNumber],
				[Instruction]
				FROM [DBO].[RepairOrderTemplate]  WITH(NOLOCK)
				WHERE [ItemMasterId] = @ItemId AND ISNULL([WorkPerformedId],0) = @WorkPerformId AND [MasterCompanyId] = @MasterCompanyID;
			END
			ELSE
			BEGIN
				SELECT 
				[RepairOrderTemplateId],
				[RepairOrderTemplateNumber],
				[Instruction]
				FROM [DBO].[RepairOrderTemplate]  WITH(NOLOCK)
				WHERE [MasterCompanyId] = @MasterCompanyID;
			END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'USP_GetSOTemplateData' 
			, @ProcedureParameters VARCHAR(3000)  = '@ItemId = '''+ ISNULL(@ItemId, '') + ''
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
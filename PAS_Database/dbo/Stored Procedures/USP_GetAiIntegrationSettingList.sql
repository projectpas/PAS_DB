/*********************     
** Author:  <BHARGAV SALIYA >    
** Create date: <July-01-2025>    
** Description: <get Ai Integration Setting Data by mastercompanyId>    
    
EXEC [USP_GetPNLabelSettingData]   
**********************   
** Change History   
**********************     
** PR   Date              Author          Change Description    
** --   --------          -------         --------------------------------  
** 1	July-01-2025	BHARGAV SALIYA    Create
** 2	July-11-2025	BHARGAV SALIYA    Modified Two Fields YearId and MonthId
** 3	Aug-07-2025	    Amit Ghediya      Modified add Fields IsAutoInternalQuote
** 4	Aug-11-2025	    Moin Bloch        Modified add Fields OpenAIAPIKeys

exec dbo.USP_GetPNLabelSettingData 1  
**********************/   

CREATE   PROCEDURE [dbo].[USP_GetAiIntegrationSettingList]
@MasterCompanyId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN 
				
				SELECT 
					 AI.AiIntegrationSettingId
					,AI.[YearId]
					,AI.[MonthId]
					,AI.[IsEnableDisableAIintegration]
					,AI.[IsReviewRequired]
					,AI.[IsAutoEmailSend]
					,AI.[IsAutoInternalQuote]
					,AI.[MasterCompanyId]
					,AI.[CreatedBy]
					,AI.[UpdatedBy]
					,AI.[CreatedDate]
					,AI.[UpdatedDate]
					,AI.[IsActive]
					,AI.[IsDeleted]
					,AI.[PercentId]
					,AI.[PercentValue]
					,AI.[OpenAIAPIKeys]
				FROM dbo.AiIntegrationSetting AI WITH(NOLOCK)
				WHERE AI.MasterCompanyId = @MasterCompanyId
                
		--	END
		--COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAiIntegrationSettingList' 
              , @ProcedureParameters VARCHAR(3000)  = '@MasterCompanyId = '''+ ISNULL(@MasterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
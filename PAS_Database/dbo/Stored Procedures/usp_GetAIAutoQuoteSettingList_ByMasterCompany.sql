/*************************************************************             
** File:   [usp_GetAIAutoQuoteSettingList_ByMasterCompany]             
** Author:   Devendra Shekh
** Description: This stored procedure is used to Get AIAuotQuoteSettings List By MasterCompanyId
** Date:   17-Sept-2025
         
**************************************************************             
** Change History             
**************************************************************             
** PR   Date				Author					Change Description  
** --   --------			-------					--------------------------------
** 1	17-Sept-2025		Devendra Shekh			Created

exec usp_GetAIAutoQuoteSettingList_ByMasterCompany 1
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetAIAutoQuoteSettingList_ByMasterCompany] (    
@MasterCompanyId INT
)    
AS    
BEGIN    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON    

	BEGIN TRY
		BEGIN  

			SELECT [AIAutoQouteSettingId]
				,[QuoteSettingNameId]
				,[QuoteSettingName]
				,[Code]
				,[Sequence]
				,[QuoteSendReviewId]
				,[QuoteSendReview]
				,[MasterCompanyId]
				,[CreatedBy]
				,[CreatedDate]
				,[UpdatedBy]
				,[UpdatedDate]
				,[IsDeleted]
				,[IsActive]
				,[YearId]
				,[MonthId]
				,[PercentId]
				,[PercentValue]
				,[Days]
			FROM [dbo].[AIAutoQouteSetting] WITH(NOLOCK)
			WHERE	[IsActive] = 1 AND [IsDeleted] = 0 AND [MasterCompanyId] = @MasterCompanyId

		END
	END TRY  
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_GetAIAutoQuoteSettingList_ByMasterCompany' 
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''
		, @ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

		exec spLogException 
		@DatabaseName			= @DatabaseName
		, @AdhocComments			= @AdhocComments
		, @ProcedureParameters		= @ProcedureParameters
		, @ApplicationName			= @ApplicationName
		, @ErrorLogID              = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END
/*************************************************************             
 ** File:  [usp_GetStocklineAsOfNowJobDetailsForCleanUp]
 ** Author:  Devendra Shekh  
 ** Description: This stored procedure is used to get the data for the CleanUp of AsofNow Reports History Data
 ** Date:   24-Feb-20265            
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			Author				Change Description              
 ** --   --------		-------				--------------------------------            
    1    24-Feb-2026	Devendra Shekh			Created  

--  EXEC [dbo].[usp_GetStocklineAsOfNowJobDetailsForCleanUp] 1, 'DEV'
************************************************************************/  
CREATE   PROCEDURE [dbo].[usp_GetStocklineAsofNowJobDetailsForCleanUp]
@MasterCompanyId INT = NULL,
@SettingEnvironment VARCHAR(50) = NULL
AS
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	BEGIN TRY  
	BEGIN  

		DECLARE @Days INT = 30;
		SELECT @Days = ISNULL([AsOfNowHistoryCleanUpDays], @Days) FROM [dbo].[AppSettings] WITH(NOLOCK) WHERE [SettingEnvironment] = @SettingEnvironment;
	
		SELECT 
			[StocklineAsofNowJobId], [Name], [Path], [TotalInventory], [JobDate], [NextRunDate], [ReportType], 
			[MasterCompanyId], [CreatedDate], [IsRunDaily]
		FROM [dbo].[StocklineAsofNowJobDetails] WITH(NOLOCK)
		WHERE [MasterCompanyId] = @MasterCompanyId
		AND ISNULL([IsRunDaily], 0) = 1
		AND CAST([CreatedDate] AS date) < CAST(DATEADD(DAY, @Days, GETUTCDATE()) AS date)
		ORDER BY [CreatedDate] DESC;

	END   
	END TRY   
	BEGIN CATCH        
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		, @AdhocComments VARCHAR(150)			= 'usp_GetStocklineAsOfNowJobDetailsForCleanUp'   
		, @ProcedureParameters VARCHAR(3000)	= '@Parameter1 = '''+ CAST(ISNULL(@masterCompanyId, '') AS VARCHAR(100)) +
												  '@Parameter2 = '''+ CAST(ISNULL(@SettingEnvironment, '') AS VARCHAR(100)) + ''
		, @ApplicationName VARCHAR(100)			= 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------  
		exec spLogException   
				@DatabaseName				= @DatabaseName  
				, @AdhocComments			= @AdhocComments  
				, @ProcedureParameters		= @ProcedureParameters  
				, @ApplicationName			=  @ApplicationName  
				, @ErrorLogID				= @ErrorLogID OUTPUT ;  
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
		RETURN(1);  
	END CATCH  
END
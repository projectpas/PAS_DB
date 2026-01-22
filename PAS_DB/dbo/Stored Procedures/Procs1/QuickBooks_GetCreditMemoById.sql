/*************************************************************           
 ** File:   [QuickBooks_GetCreditMemoById]           
 ** Author:   Devendra Shekh
 ** Description: Get QuickBook Credit Memo By QuickBooksReferenceId
 ** Purpose:         
 ** Date:   12-Feb-2025	        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author						Change Description            
 ** --   --------			-------					--------------------------------          
    1   12-Feb-2025			Devendra Shekh				Created
     
 exec dbo.QuickBooks_GetCreditMemoById @QuickBooksReferenceId=N'185',@MasterCompanyId=1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetCreditMemoById]
	@QuickBooksReferenceId VARCHAR(256) = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @CredtitMemoModuleId INT = 0, @CMModuleId INT = 0;
		DECLARE @CredtitMemoModuleName VARCHAR(200) = '';

		SELECT @CredtitMemoModuleId = AccountingModuleId, @CredtitMemoModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE AccountingModuleName = 'CredtitMemo';
		SELECT @CMModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'CredtitMemo';

		IF OBJECT_ID('tempdb..#CreditMemoDetails') IS NOT NULL
			DROP TABLE #CreditMemoDetails

		CREATE TABLE #CreditMemoDetails
		(
			[RecordId] BIGINT IDENTITY(1,1) NOT NULL,
			[CreditMemoHeaderId] BIGINT NULL,
			[QuickBooksReferenceId] BIGINT NULL,
			[SyncToken] VARCHAR(200) NULL,
			[ModuleId] BIGINT NULL,
			[ReferenceModuleId] BIGINT NULL,
		)

		INSERT INTO #CreditMemoDetails([CreditMemoHeaderId], [QuickBooksReferenceId], [SyncToken], [ModuleId], [ReferenceModuleId])
		SELECT CM.CreditMemoHeaderId, CM.QuickBooksReferenceId, CM.SyncToken, @CredtitMemoModuleId, @CMModuleId
		FROM [dbo].[CreditMemo] CM WITH(NOLOCK) WHERE CM.QuickBooksReferenceId = @QuickBooksReferenceId AND CM.MasterCompanyId = @MasterCompanyId;

		SELECT * FROM #CreditMemoDetails;
		
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetCreditMemoById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@QuickBooksReferenceId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END
/*************************************************************           
 ** File:   [QuickBooks_GetNewGLAccountSyncPendingListForCreate]           
 ** Author:   Devendra Shekh
 ** Description: Get GL Account List to Create Account in QuickBooks By Id   
 ** Purpose:         
 ** Date:   30-Jan-2025        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   30-Jan-2025		Devendra Shekh			Created
     
 EXECUTE [QuickBooks_GetNewGLAccountSyncPendingListForCreate] 1, 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetNewGLAccountSyncPendingListForCreate]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		IF OBJECT_ID('tempdb..#GLAccountDetails') IS NOT NULL
			DROP TABLE #GLAccountDetails

		CREATE TABLE #GLAccountDetails
		(
			[Id] BIGINT IDENTITY(1,1) NOT NULL,
			[GLAccountId] BIGINT NULL,
			[GLAccountName] VARCHAR(200) NULL,
			[AccountDescription] VARCHAR(500) NULL,
			[AccountType] VARCHAR(200) NULL,
			[AccountSubType] VARCHAR(200) NULL,
			[CurrentBalance] DECIMAL(9,2) NULL,
			[SubAccount] BIT NULL,
			[IsActive] BIT NULL,
			[QuickBooksReferenceId] VARCHAR(200) NULL,
			[SyncToken] VARCHAR(200) NULL,
			[MasterCompanyId] INT NULL,
			[UpdatedBy] VARCHAR(256) NULL,
		)

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			INSERT INTO #GLAccountDetails ([GLAccountId], [GLAccountName], [AccountDescription], [AccountType], [AccountSubType], [CurrentBalance], [SubAccount], [IsActive], [QuickBooksReferenceId], [SyncToken], [MasterCompanyId], [UpdatedBy])
			SELECT	GL.[GLAccountId],
					GL.[AccountCode] + ' - ' + GL.[AccountName],
					ISNULL(GL.[AccountDescription], ''),
					ISNULL(GLC.[GLAccountClassName], ''),
					'',
					0,
					0,
					GL.[IsActive],
					ISNULL(GL.QuickBooksReferenceId, '0'),
					ISNULL(GL.SyncToken, '0'),
					GL.MasterCompanyId,
					GL.UpdatedBy					 
			FROM [dbo].[GLAccount] GL WITH(NOLOCK) 
				LEFT JOIN [dbo].[GLAccountClass] GLC WITH(NOLOCK) ON GLC.GLAccountClassId = GL.GLAccountTypeId
			WHERE ISNULL(GL.QuickBooksReferenceId, 0) = 0 AND ISNULL(GL.IsUpdated, 0) = 1 AND GL.MasterCompanyId = @MasterCompanyId
		END

		SELECT * FROM #GLAccountDetails;

	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetNewGLAccountSyncPendingListForCreate'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
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
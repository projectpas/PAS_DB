/*************************************************************           
 ** File:   [QuickBooks_GetPurchaseOrderById]           
 ** Author:   Abhishek Jirawla
 ** Description: Get QuickBook PurchaseOrder By QuickBooksReferenceId
 ** Purpose:         
 ** Date:   07-Feb-2025       
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   07-Feb-2025		Abhishek Jirawla		Created
     
 exec dbo.QuickBooks_GetPurchaseOrderById @QuickBooksReferenceId=N'185',@MasterCompanyId=1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[QuickBooks_GetPurchaseOrderById]
	@QuickBooksReferenceId VARCHAR(256) = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @InvModuleId INT = 0, @POModuleId INT = 0, @POModuleName VARCHAR(200) = '', @ROModuleId INT = 0, @ROModuleName VARCHAR(200) = '';
		DECLARE @InvModuleName VARCHAR(200) = '';

		SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE [AccountingModuleName] = 'PurchaseOrder';
		SELECT @POModuleId = ModuleId, @POModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'PurchaseOrder';
		SELECT @ROModuleId = ModuleId, @ROModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'RepairOrder';

		IF OBJECT_ID('tempdb..#ReferenceResults') IS NOT NULL
			DROP TABLE #ReferenceResults

		CREATE TABLE #ReferenceResults
		(
			[RecordId] BIGINT IDENTITY(1,1) NOT NULL,
			[ReferenceId] BIGINT NULL,
			[QuickBooksReferenceId] BIGINT NULL,
			[SyncToken] VARCHAR(200) NULL,
			[ModuleId] BIGINT NULL,
			[ReferenceModuleId] BIGINT NULL,
		)

		INSERT INTO #ReferenceResults([ReferenceId], [QuickBooksReferenceId], [SyncToken], [ModuleId], [ReferenceModuleId])
		SELECT PO.PurchaseOrderId, PO.QuickBooksReferenceId, PO.SyncToken, @InvModuleId, @POModuleId
		FROM [dbo].[PurchaseOrder] PO WITH(NOLOCK) WHERE PO.QuickBooksReferenceId = @QuickBooksReferenceId AND PO.MasterCompanyId = @MasterCompanyId;

		INSERT INTO #ReferenceResults([ReferenceId], [QuickBooksReferenceId], [SyncToken], [ModuleId], [ReferenceModuleId])
		SELECT RO.RepairOrderId, RO.QuickBooksReferenceId, RO.SyncToken, @InvModuleId, @ROModuleId
		FROM [dbo].[RepairOrder] RO WITH(NOLOCK) WHERE RO.QuickBooksReferenceId = @QuickBooksReferenceId AND RO.MasterCompanyId = @MasterCompanyId;

		SELECT * FROM #ReferenceResults;
		
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetInvoiceById'
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
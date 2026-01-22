/*************************************************************           
 ** File:   [QuickBooks_GetInvoiceById]           
 ** Author:   Devendra Shekh
 ** Description: Get QuickBook Invoice By QuickBooksReferenceId
 ** Purpose:         
 ** Date:   18-Nov-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   18-Nov-2024		Devendra Shekh			Created
	2   03-Feb-2025		Devendra Shekh			Modified (Using [AccountingModule] table for Accounting Modules)
	3   19-Jun-2025		Moin Bloch			    Modified (Using New Billing Table)
     
 exec dbo.QuickBooks_GetInvoiceById @QuickBooksReferenceId=N'185',@MasterCompanyId=1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetInvoiceById]
	@QuickBooksReferenceId VARCHAR(256) = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @InvModuleId INT = 0, @WOModuleId INT = 0, @SOModuleId INT = 0, @ExchModuleId INT = 0;
		DECLARE @InvModuleName VARCHAR(200) = '';

		SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE AccountingModuleName = 'Invoice';
		SELECT @WOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @ExchModuleId = ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';

		IF OBJECT_ID('tempdb..#InvoiceResults') IS NOT NULL
			DROP TABLE #InvoiceResults

		CREATE TABLE #InvoiceResults
		(
			[RecordId] BIGINT IDENTITY(1,1) NOT NULL,
			[BillingInvoicingId] BIGINT NULL,
			[QuickBooksReferenceId] BIGINT NULL,
			[SyncToken] VARCHAR(200) NULL,
			[ModuleId] BIGINT NULL,
			[ReferenceModuleId] BIGINT NULL,
		)

		--OLD Table
		--INSERT INTO #InvoiceResults([BillingInvoicingId], [QuickBooksReferenceId], [SyncToken], [ModuleId], [ReferenceModuleId])
		--SELECT WOBI.BillingInvoicingId, WOBI.QuickBooksReferenceId, WOBI.SyncToken, @InvModuleId, @WOModuleId
		--FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK) WHERE WOBI.QuickBooksReferenceId = @QuickBooksReferenceId AND WOBI.MasterCompanyId = @MasterCompanyId;

		--INSERT INTO #InvoiceResults([BillingInvoicingId], [QuickBooksReferenceId], [SyncToken], [ModuleId], [ReferenceModuleId])
		--SELECT SOBI.SOBillingInvoicingId, SOBI.QuickBooksReferenceId, SOBI.SyncToken, @InvModuleId, @SOModuleId
		--FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH(NOLOCK) WHERE SOBI.QuickBooksReferenceId = @QuickBooksReferenceId AND SOBI.MasterCompanyId = @MasterCompanyId;

		-- NEW Table
		INSERT INTO #InvoiceResults([BillingInvoicingId], [QuickBooksReferenceId], [SyncToken], [ModuleId], [ReferenceModuleId])
		SELECT WOBI.BillingInvoicingId, WOBI.QuickBooksReferenceId, WOBI.SyncToken, @InvModuleId, @WOModuleId
		FROM [dbo].[BillingInvoicing] WOBI WITH(NOLOCK) WHERE WOBI.QuickBooksReferenceId = @QuickBooksReferenceId AND WOBI.MasterCompanyId = @MasterCompanyId;

		INSERT INTO #InvoiceResults([BillingInvoicingId], [QuickBooksReferenceId], [SyncToken], [ModuleId], [ReferenceModuleId])
		SELECT SOBI.BillingInvoicingId, SOBI.QuickBooksReferenceId, SOBI.SyncToken, @InvModuleId, @SOModuleId
		FROM [dbo].[BillingInvoicing] SOBI WITH(NOLOCK) WHERE SOBI.QuickBooksReferenceId = @QuickBooksReferenceId AND SOBI.MasterCompanyId = @MasterCompanyId;

		INSERT INTO #InvoiceResults([BillingInvoicingId], [QuickBooksReferenceId], [SyncToken], [ModuleId], [ReferenceModuleId])
		SELECT ESOBI.SOBillingInvoicingId, ESOBI.QuickBooksReferenceId, ESOBI.SyncToken, @InvModuleId, @ExchModuleId
		FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH(NOLOCK) WHERE ESOBI.QuickBooksReferenceId = @QuickBooksReferenceId AND ESOBI.MasterCompanyId = @MasterCompanyId;

		SELECT * FROM #InvoiceResults;
		
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
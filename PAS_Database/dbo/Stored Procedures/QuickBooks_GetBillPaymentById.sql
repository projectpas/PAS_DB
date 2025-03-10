/*************************************************************           
 ** File:   [QuickBooks_GetBillPaymentById]           
 ** Author:   Abhishek Jirawla
 ** Description: Get QuickBook Bill Payment By BillPaymentId
 ** Purpose:         
 ** Date:   04-Mar-2025
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   04-Mar-2025		Abhishek Jirawla		Created
     
 exec dbo.QuickBooks_GetBillPaymentById @BillPaymentId=N'185',@MasterCompanyId=1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[QuickBooks_GetBillPaymentById]
	@QuickBooksReferenceId VARCHAR(256) = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		DECLARE @InvModuleId INT = 0, @BillPaymentModuleId INT = 0, @BillPaymentModuleName VARCHAR(200) = '';
		DECLARE @InvModuleName VARCHAR(200) = '';

		SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE [AccountingModuleName] = 'BillPayment';
		SELECT @BillPaymentModuleId = ModuleId, @BillPaymentModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'BillPayment';

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
		SELECT VRTPD.ReadyToPayDetailsId, VRTPD.QuickBooksReferenceId, VRTPD.SyncToken, @InvModuleId, @BillPaymentModuleId
		FROM [dbo].[VendorReadyToPayDetails] VRTPD WITH(NOLOCK) WHERE VRTPD.QuickBooksReferenceId = @QuickBooksReferenceId AND VRTPD.MasterCompanyId = @MasterCompanyId;

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
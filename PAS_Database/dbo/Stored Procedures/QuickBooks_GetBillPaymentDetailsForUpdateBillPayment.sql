/*************************************************************           
 ** File:   [QuickBooks_GetBillPaymentDetailsForUpdateBillPayment]           
 ** Author:   Abhishek Jirawla
 ** Description: Get BillPayment Details to Update BillPayment in QuickBooks    
 ** Purpose:         
 ** Date:   04-Mar-2025       
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    04-Mar-2025   Abhishek Jirawla	Created
     
 EXECUTE [QuickBooks_GetNewBillPaymentListForCreateBillPayment] 1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[QuickBooks_GetBillPaymentDetailsForUpdateBillPayment]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferenceModuleId INT = NULL
AS
BEGIN
	DECLARE @InvModuleId INT = 0, @BillPaymentModuleId INT = 0, @BillPaymentModuleName VARCHAR(200) = '';
	DECLARE @InvModuleName VARCHAR(200) = '';
	
	SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'BillPayment';
	SELECT @BillPaymentModuleId = ModuleId, @BillPaymentModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'VendorPayment';

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1)
		BEGIN
			DECLARE @Check INT;
			SELECT @Check = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Check';

			SELECT '' AS PrivateNote,
				VN.QuickBooksReferenceId AS VendorValue,
				VN.VendorName AS VendorName,
				ISNULL(VRTPD.PaymentMade,0) AS TotalAmt,
				--CASE WHEN VRTPD.IsVoidedCheck = 1 THEN VRTPD.CheckNumber + ' (V)' ELSE VRTPD.CheckNumber END AS PayType,
				'Check' AS PayType,
				VRTPD.PaymentMade AS Amount,
				NPO.QuickBooksReferenceId AS TxnId,
				--'1234' AS TxnId,
				'Bill' AS TxnType,
				--lebl.BankName AS BankAccountName,
				--CASE WHEN VRTPD.IsVoidedCheck = 1 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber + ' (V)'
				--	WHEN VRTPD.IsVoidedCheck = 0 AND VRTPD.PaymentMethodId = @Check THEN lebl.BankAccountNumber
				--	ELSE ''
				--END AS 'BankAccountValue',
				GL.AccountName AS BankAccountName,
				GL.QuickBooksReferenceId AS BankAccountValue,
				VRTPD.ReadyToPayDetailsId AS ReferenceId,
				@BillPaymentModuleId,
				@BillPaymentModuleName,
				VRTPD.MasterCompanyId,
				VRTPD.UpdatedBy,
				VRTPD.QuickBooksReferenceId,
				VRTPD.SyncToken
			FROM [dbo].[VendorReadyToPayDetails] VRTPD  WITH(NOLOCK)
				INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VRTPD.VendorId = VN.VendorId
				LEFT JOIN [dbo].[VendorReadyToPayHeader] VRTPDH WITH(NOLOCK) ON VRTPD.ReadyToPayId = VRTPDH.ReadyToPayId
				LEFT JOIN [dbo].[NonPOInvoiceHeader] NPO WITH(NOLOCK) ON NPO.NonPOInvoiceId = VRTPD.NonPOInvoiceId
				LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = VRTPDH.CashGLAccountId
			WHERE ISNULL(VRTPD.QuickBooksReferenceId, 0) = 0 AND ISNULL(VRTPD.IsUpdated, 0) = 1 AND VRTPD.MasterCompanyId = @MasterCompanyId AND VRTPD.ReadyToPayDetailsId = @ReferenceId
		END
	END TRY
	BEGIN CATCH

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetBillPaymentDetailsForUpdateBillPayment'
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
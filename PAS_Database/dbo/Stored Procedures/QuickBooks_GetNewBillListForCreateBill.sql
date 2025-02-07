/*************************************************************           
 ** File:   [QuickBooks_GetNewBillListForCreateBill]           
 ** Author:   Abhishek Jirawla
 ** Description: Get Bill List to Create Bill in QuickBooks    
 ** Purpose:         
 ** Date:   03-Feb-2025       
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    03-Feb-2025   Abhishek Jirawla	Created
     
 EXECUTE [QuickBooks_GetNewBillListForCreateBill] 1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[QuickBooks_GetNewBillListForCreateBill]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL,
	@ReferenceModuleId INT = NULL
AS
BEGIN
	DECLARE @Check INT;
	DECLARE @InvModuleId INT = 0, @NonPOModuleId INT = 0, @NonPOModuleName VARCHAR(200) = '';
	DECLARE @InvModuleName VARCHAR(200) = '';
	SELECT @Check = [VendorPaymentMethodId] FROM [dbo].[VendorPaymentMethod] WITH(NOLOCK) WHERE Description = 'Check';

	SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'Bill';
	SELECT @NonPOModuleId = ModuleId, @NonPOModuleName = ModuleName FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'NonPOInvoice';


	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			IF(ISNULL(@ReferenceModuleId, 0) = ISNULL(@NonPOModuleId, 0)) 
			BEGIN
				SELECT NPO.NonPOInvoiceId AS InvoiceId,
					VN.QuickBooksReferenceId AS VendorValue,
					VN.VendorName AS VendorName,
					SUM(ISNULL(NPOPD.ExtendedPrice, 0)) AS TotalAmt,
					GL.QuickBooksReferenceId AS BillAPAccountValue,
					GL.AccountName AS BillAPAccountName,
					ISNULL(NPOPD.ExtendedPrice, 0) AS Amount,
					@InvModuleName AS ModuleName,
					@InvModuleId AS ModuleId,
					NPO.MasterCompanyId,
					NPO.UpdatedBy,
					@NonPOModuleId AS ReferenceModuleId,
					@NonPOModuleName AS ReferenceModuleName
				FROM [dbo].[NonPOInvoiceHeader] NPO WITH(NOLOCK)
					INNER JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON NPO.VendorId = VN.VendorId
					LEFT JOIN [dbo].[NonPOInvoicePartDetails] NPOPD WITH(NOLOCK) ON NPO.NonPOInvoiceId = NPOPD.NonPOInvoiceId
					LEFT JOIN [dbo].[GLAccount] GL WITH(NOLOCK) ON GL.GLAccountId = NPOPD.GlAccountId
				WHERE ISNULL(NPO.QuickBooksReferenceId, 0) = 0 AND ISNULL(NPO.IsUpdated, 0) = 1 AND NPO.NonPOInvoiceId = @ReferenceId AND NPO.MasterCompanyId = @MasterCompanyId
				GROUP BY NPO.NonPOInvoiceId,
					VN.QuickBooksReferenceId,
					VN.VendorName,
					NPOPD.ExtendedPrice,
					GL.QuickBooksReferenceId,
					GL.AccountName,
					NPO.MasterCompanyId,
					NPO.UpdatedBy
			END
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetNewBillListForCreateBill'
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
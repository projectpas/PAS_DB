/****************************************************************************************     
** Author:  <RAJESH GAMI>    
** Create date: <17-Dec-2024>    
** Description: <Get Vendor Proforma Invoice Edit Data By VendorProformaInvoiceId for edit>    
    
EXEC [USP_GetVendorProformaInvoiceEditData_ById]   
**********************   
** Change History   
*****************************************************************************************     
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    17-Dec-2024		RAJESH GAMI		    CREATED
** 2    25-Dec-2024		RAJESH GAMI		    Get ControlNumber
** 3    30-Dec-2024		RAJESH GAMI		    Get TotalPartCount

exec dbo.USP_GetVendorProformaInvoiceEditData_ById 10,1
*****************************************************************************************/   

CREATE     PROCEDURE [dbo].[USP_GetVendorProformaInvoiceEditData_ById]
@VendorProformaInvoiceId bigint,
@MasterCompanyId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				DECLARE @totalPartCount int = (SELECT COUNT(1) FROM dbo.VendorProformaInvoicePartDetails WITH(NOLOCK) WHERE VendorProformaInvoiceId = @VendorProformaInvoiceId)
				SELECT DISTINCT
						NPH.[VendorProformaInvoiceId],
						NPH.[VendorId],
						NPH.[VendorName],
						NPH.[VendorCode],
						NPH.[PaymentTermsId],
						NPH.[StatusId],
						NPH.[ManagementStructureId],
						NPHS.[Description] AS [InvoiceStatus],
						CT.[Name] AS [PaymentTerms],
						NPH.[IsActive],
						NPH.[IsDeleted],
						NPH.[CreatedDate],
						NPH.[UpdatedDate],
						Upper(NPH.[CreatedBy]) CreatedBy,
						Upper(NPH.[UpdatedBy]) UpdatedBy,
						NPH.[MasterCompanyId],
						NPH.[PaymentMethodId],
						NPH.[EmployeeId],
						ISNULL(NPH.IsEnforcePoRoApproval, 0) AS IsEnforcePoRoApproval,
						NPH.[VendorProformaInvoiceNo],
						NPH.[EntryDate],
						ISNULL(NPH.[InvoiceNumber], '') AS [InvoiceNumber],
						NPH.[InvoiceDate],
						ISNULL(NPH.[ReferenceNumber], '') AS [ReferenceNumber],
						ISNULL(NPH.[AccountingCalendarId], 0) AS [AccountingCalendarId],
						ISNULL(NPH.[CurrencyId], 0) AS [CurrencyId],
						NPH.[ReferenceId],
						NPH.[ReferenceModuleId],
						NPH.[ControlNumber],
						@totalPartCount as TotalPartCount
				FROM [dbo].[VendorProformaInvoiceHeader] NPH WITH (NOLOCK)
				INNER JOIN [dbo].[VendorProformaInvoiceHeaderStatus] NPHS WITH (NOLOCK) ON NPHS.VendorProformaInvoiceHeaderStatusId = NPH.StatusId
				 LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = NPH.PaymentTermsId
                WHERE NPH.VendorProformaInvoiceId = @VendorProformaInvoiceId AND NPH.MasterCompanyId = @MasterCompanyId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorProformaInvoiceEditData_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@VendorProformaInvoiceId = '''+ ISNULL(@VendorProformaInvoiceId, '') + ''
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
/****************************************************************************************     
** Author:  <Devendra Shekh>    
** Create date: <09/14/2023>    
** Description: <get NOnPOInvoice Data by NonPOInvoiceId for edit>    
    
EXEC [USP_GetNonPOInvoiceEditData_ById]   
**********************   
** Change History   
*****************************************************************************************     
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    09/14/2023		Devendra Shekh		 created
** 2    09/14/2023		Devendra Shekh		 ADDED employeeid and IsEnforceNonPoApproval
** 3    09/14/2023		Devendra Shekh		 ADDED NPONumber
** 4    10/11/2023		Devendra Shekh		 ADDED new columns
** 5    10/26/2023		Devendra Shekh		 ADDED new columns
** 6    11/01/2024	    Moin Bloch 			 ADDED new columns ReferenceId,ReferenceModuleId

exec dbo.USP_GetNonPOInvoiceEditData_ById 1,1
*****************************************************************************************/   

CREATE   PROCEDURE [dbo].[USP_GetNonPOInvoiceEditData_ById]
@NonPOInvoiceId bigint,
@MasterCompanyId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT DISTINCT
						NPH.[NonPOInvoiceId],
						NPH.[VendorId],
						NPH.[VendorName],
						NPH.[VendorCode],
						NPH.[PaymentTermsId],
						NPH.[StatusId],
						NPH.[ManagementStructureId],
						NPHS.[Description] AS [NonPoInvoiceStatus],
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
						ISNULL(NPH.[IsEnforceNonPoApproval], 0) AS IsEnforceNonPoApproval,
						NPH.[NPONumber],
						NPH.[EntryDate],
						ISNULL(NPH.[InvoiceNumber], '') AS [InvoiceNumber],
						NPH.[InvoiceDate],
						ISNULL(NPH.[PONumber], '') AS [PONumber],
						ISNULL(NPH.[AccountingCalendarId], 0) AS [AccountingCalendarId],
						ISNULL(NPH.[CurrencyId], 0) AS [CurrencyId],
						NPH.[ReferenceId],
						NPH.[ReferenceModuleId]
				FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)
				INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH (NOLOCK) ON NPHS.NonPOInvoiceHeaderStatusId = NPH.StatusId
				 LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = NPH.PaymentTermsId
                WHERE NPH.NonPOInvoiceId = @NonPOInvoiceId AND NPH.MasterCompanyId = @MasterCompanyId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetNonPOInvoiceEditData_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@NonPOInvoiceId = '''+ ISNULL(@NonPOInvoiceId, '') + ''
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
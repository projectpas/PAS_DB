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
** 7    12/27/2024		AMIT GHEDIYA		 Modify(Added ControlNumber Field)
** 8    01-Jan-2025		AYUSHI PATEL		 Get TotalPartCount
** 9    28-Jan-2026		SAHDEV SALIYA		 Added DueDate
** 10   12-Aug-2026		RAJESH GAMI		 Improve Performance : the @totalPartCount subquery now
									 benefits from IX_NonPOInvoicePartDetails_NonPOInvoiceId_Perf
									 (added on NonPOInvoicePartDetails.NonPOInvoiceId under this
									 same ticket for USP_GetNonPOInvoiceList) - previously it was
									 a full table scan on every single call to this API. Also
									 removed SELECT DISTINCT (the query is already a single-row
									 lookup by NonPOInvoiceId's clustered PK, joined 1:1 to two
									 small lookup tables, so DISTINCT had nothing to deduplicate)
									 and removed the explicit BEGIN/COMMIT TRANSACTION wrapper
									 around what is a pure read with no writes - it added
									 transaction-management overhead for no benefit. [PN-17634]

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
			BEGIN
				-- PERF FIX: this subquery now seeks IX_NonPOInvoicePartDetails_NonPOInvoiceId_Perf
				-- instead of scanning the whole NonPOInvoicePartDetails table (see history #10).
				DECLARE @totalPartCount int = (SELECT COUNT(1) FROM dbo.NOnPOInvoicePartDetails WITH(NOLOCK) WHERE NonPOInvoiceId = @NonPOInvoiceId)
				-- PERF FIX: removed SELECT DISTINCT - this is a single-row lookup by the
				-- NonPOInvoiceId clustered PK, joined 1:1 to two small lookup tables, so there is
				-- nothing for DISTINCT to deduplicate.
				SELECT
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
						NPH.[ReferenceModuleId],
						NPH.[ControlNumber],
						NPH.[DueDate],
						@totalPartCount as TotalPartCount
				FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)
				INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH (NOLOCK) ON NPHS.NonPOInvoiceHeaderStatusId = NPH.StatusId
				 LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = NPH.PaymentTermsId
                WHERE NPH.NonPOInvoiceId = @NonPOInvoiceId AND NPH.MasterCompanyId = @MasterCompanyId
			END

		END TRY
		BEGIN CATCH
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
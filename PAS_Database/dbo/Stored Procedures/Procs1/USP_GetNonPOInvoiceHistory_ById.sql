/*********************     
** Author:  <Devendra Shekh>    
** Create date: <09/14/2023>    
** Description: <get NOnPOInvoice history Data by NonPOInvoiceId>    
    
EXEC [USP_GetPNLabelSettingData]   
**********************   
** Change History   
**********************     
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    09/14/2023		Devendra Shekh		 created

exec dbo.USP_GetNonPOInvoiceHistory_ById 1,1
**********************/   

Create   PROCEDURE [dbo].[USP_GetNonPOInvoiceHistory_ById]
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
						NPHA.NonPOInvoiceHeaderAuditId,
						NPHA.NonPOInvoiceId,
						NPHA.VendorId,
						NPHA.VendorName,
						NPHA.VendorCode,
						NPHA.PaymentTermsId,
						NPHA.StatusId,
						NPHA.ManagementStructureId,
						NPHS.Description AS [NonPoInvoiceStatus],
						CT.Name AS [PaymentTerms],
						NPHA.IsActive,
						NPHA.IsDeleted,
						NPHA.CreatedDate,
						NPHA.UpdatedDate,
						Upper(NPHA.CreatedBy) CreatedBy,
						Upper(NPHA.UpdatedBy) UpdatedBy,
						NPHA.MasterCompanyId,
						NPH.PaymentMethodId
				FROM [dbo].[NonPOInvoiceHeaderAudit] NPHA WITH (NOLOCK)
				INNER JOIN [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK) ON NPH.NonPOInvoiceId = NPHA.NonPOInvoiceId
				INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH (NOLOCK) ON NPHS.NonPOInvoiceHeaderStatusId = NPHA.StatusId
				LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = NPHA.PaymentTermsId
                WHERE NPHA.NonPOInvoiceId = @NonPOInvoiceId AND NPHA.MasterCompanyId = @MasterCompanyId
				ORDER BY NPHA.NonPOInvoiceHeaderAuditId DESC
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetNonPOInvoiceHistory_ById' 
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
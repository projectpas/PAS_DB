/*********************     
** Author:  <RAJESH GAMI>    
** Create date: <09/14/2023>    
** Description: <Get Vendor Proforma Invoice History By VendorProformaInvoiceId>    
    
EXEC [USP_GetPNLabelSettingData]   
**********************   
** Change History   
**********************     
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    09/14/2023		RAJESH GAMI		 created
   2	10/04/2025	    Ekta Chandegra	Convert date using dbo.ConvertUTCtoLocal

exec dbo.USP_GetProformaInvoiceHistory_ById 1,1
**********************/   

CREATE     PROCEDURE [dbo].[USP_GetProformaInvoiceHistory_ById]
@VendorProformaInvoiceId bigint,
@MasterCompanyId bigint,
@EmployeeId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT DISTINCT
						VPHA.VendorProformaInvoiceAuditId,
						VPHA.VendorProformaInvoiceId,
						VPHA.VendorId,
						VPHA.VendorName,
						VPHA.VendorCode,
						VPHA.PaymentTermsId,
						VPHA.StatusId,
						VPHA.ManagementStructureId,
						VPHS.Description AS [InvoiceStatus],
						CT.Name AS [PaymentTerms],
						VPHA.IsActive,
						VPHA.IsDeleted,
						(Cast(DBO.ConvertUTCtoLocal(VPHA.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as CreatedDate,
						(Cast(DBO.ConvertUTCtoLocal(VPHA.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as UpdatedDate,
						Upper(VPHA.CreatedBy) CreatedBy,
						Upper(VPHA.UpdatedBy) UpdatedBy,
						VPHA.MasterCompanyId,
						VPH.PaymentMethodId
				FROM [dbo].[VendorProformaInvoiceHeaderAudit] VPHA WITH (NOLOCK)
				INNER JOIN [dbo].[VendorProformaInvoiceHeader] VPH WITH (NOLOCK) ON VPH.VendorProformaInvoiceId = VPHA.VendorProformaInvoiceId
				INNER JOIN [dbo].[VendorProformaInvoiceHeaderStatus] VPHS WITH (NOLOCK) ON VPHS.VendorProformaInvoiceHeaderStatusId = VPHA.StatusId
				LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = VPHA.PaymentTermsId
                WHERE VPHA.VendorProformaInvoiceId = @VendorProformaInvoiceId AND VPHA.MasterCompanyId = @MasterCompanyId
				ORDER BY VPHA.VendorProformaInvoiceAuditId DESC
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetProformaInvoiceHistory_ById' 
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
/*************************************************************               
 ** File:   [USP_PrintCheckSetup_GetHistorById]               
 ** Author:     
 ** Description: This stored procedure is used Print Check Setup History By Id.  
 ** Purpose:             
 ** Date:          
              
 ** PARAMETERS:     
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date				Author				Change Description                
 ** --   --------			-------				--------------------------------              
	1    ***********		Unknown				Created
	2    06-Mar-2025		Divyesh Kathiriya	Update CreatedDate and UpdateDate based on Employee time zone 
	
	exec [USP_PrintCheckSetup_GetHistorById] 1,226
************************************************************************/    


CREATE   PROCEDURE [dbo].[USP_PrintCheckSetup_GetHistorById]
@PrintingId bigint,
@EmployeeId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
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
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

				SELECT 
					t.AuditPrintingId,
					t.PrintingId,
					t.StartNum,
					t.ConfirmStartNum,
					t.BankId,
					ISNULL(t.BankName,'') AS BankName,
					t.BankAccountId,
					ISNULL(t.BankAccountNumber,'') AS  BankAccountNumber,
					t.GLAccountId,
					ISNULL(t.GlAccount,'') AS GlAccount,
					t.ConfirmBankAccInfo,
					ISNULL(t.BankRef,'') AS BankRef,
					ISNULL(t.CcardPaymentRef,'') AS CcardPaymentRef,
					CASE WHEN t.[Type] = 1 THEN 'Check' WHEN t.[Type] = 2 THEN 'Wire' WHEN t.[Type] = 3 THEN 'Credit Card' ELSE '' END as 'TypeName',
					t.Type,
					t.MasterCompanyId,
					t.CreatedBy,
					t.UpdatedBy,
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						 CASE WHEN CAST(t.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(t.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					ELSE (CAST(t.CreatedDate AS DATETIME)) END CreatedDate,
					CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						 CASE WHEN CAST(t.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(t.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					ELSE (CAST(t.UpdatedDate AS DATETIME)) END UpdatedDate,
					t.IsActive,
					t.IsDeleted
				FROM [DBO].[PrintCheckSetupAudit] t WITH (NOLOCK) 
				WHERE t.PrintingId = @PrintingId ORDER BY t.AuditPrintingId DESC
				--WHERE t.PrintingId = @PrintingId AND t.BankName IS NOT NUll ORDER BY t.PrintingId DESC
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PrintCheckSetup_GetHistorById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PrintingId, '') + ''
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
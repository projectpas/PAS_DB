/***************************************************************  
 ** File:   [GetInvoicePaymentsHistory]            
 ** Author:   Unknown
 ** Description: This stored procedure is used to Get Invoice Payments History.
 ** Date:  Unknown
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    ***********		Unknown				Created
    2    20-Mar-2025		Divyesh Kathiriya	Update CreatedDate, UpdateDate and InvoiceDate based on Employee time zone 
		
	EXEC dbo.GetInvoicePaymentsHistory @InvoicingId=124,@ReceiptId=10133,@EmployeeId=226
**************************************************************/

CREATE PROCEDURE [dbo].[GetInvoicePaymentsHistory]
@InvoicingId BIGINT,
@ReceiptId BIGINT,
@EmployeeId BIGINT
AS
BEGIN
	BEGIN TRY
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					DBO.Employee E WITH (NOLOCK) 
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

			SELECT iv.PaymentAuditId,
				   iv.ReceiptId,
				   cp.ReceiptNo,
				   iv.DocNum,
				   iv.WOSONum,				   
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(iv.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(iv.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(iv.InvoiceDate AS DATETIME)) END InvoiceDate,
				   iv.OriginalAmount,
				   iv.RemainingAmount,
				   iv.NewRemainingBal,
				   iv.PaymentAmount,
				   iv.DiscAmount,
				   dt.[Name] 'DiscType',
				   iv.BankFeeAmount,
				   bf.[Name] 'BankFeeType',
				   iv.OtherAdjustAmt,
				   ar.[Name] 'Reason',
				   iv.IsDeleted,
				   iv.CreatedBy,
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(iv.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(iv.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(iv.CreatedDate AS DATETIME)) END CreatedDate,
				   iv.UpdatedBy,
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(iv.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(iv.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(iv.UpdatedDate AS DATETIME)) END UpdatedDate
			  FROM dbo.InvoicePaymentsAudit iv WITH (NOLOCK)
			  INNER JOIN CustomerPayments cp WITH (NOLOCK) on iv.ReceiptId=cp.ReceiptId
			  LEFT JOIN dbo.MasterDiscountType dt WITH (NOLOCK) on iv.DiscType=dt.Id
			  LEFT JOIN dbo.MasterBankFeesType bf WITH (NOLOCK) on iv.BankFeeType=bf.Id
			  LEFT JOIN dbo.MasterAdjustReason ar WITH (NOLOCK) on iv.Reason=ar.Id
			  WHERE iv.SOBillingInvoicingId = @InvoicingId 
			  ORDER BY iv.PaymentAuditId DESC
			  --AND iv.ReceiptId = @ReceiptId;
	END TRY    
	BEGIN CATCH 
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()		

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments VARCHAR(150) = 'GetInvoicePaymentsHistory' 
              , @ProcedureParameters VARCHAR(3000)  = ''
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
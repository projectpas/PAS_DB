/*************************************************************           
 ** File:   [USP_GetExchangeQuoteApprovalListNew]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuoteApprovalListNew
 ** Purpose:         
 ** Date:   07/03/2025      
          
 ** PARAMETERS:  @ExchangeQuoteId BIGINT, @InternalApprove BIT, @EmployeeId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/03/2025   Ekta Chandegra     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    20/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 filter from ItemMaster LEFT JOIN so Non-Stock parts show full details in the Exchange SOQ approval list.
  EXEC USP_GetExchangeQuoteApprovalListNew @ExchangeQuoteId = 113, @InternalApprove = 1, @EmployeeId = 237
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteApprovalListNew]
    @ExchangeQuoteId BIGINT,
    @InternalApprove BIT,
    @EmployeeId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @PendingApprovalStatusId INT;
		SELECT @PendingApprovalStatusId = ApprovalStatusId FROM [dbo].[ApprovalStatus] WITH(NOLOCK) WHERE Name = 'Pending';


		-- Get Employee TimeZone Description
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH(NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH(NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH(NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH(NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId; 


		DECLARE @IsApprovalRule BIT;
		SELECT TOP 1 @IsApprovalRule = IsApprovalRule
		FROM [dbo].[ExchangeQuoteSetting] WITH(NOLOCK)
		WHERE ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0;


		SELECT DISTINCT
			EQ.ExchangeQuoteId,
			EQ.ExchangeQuoteNumber,
			EQ.Version,
			EQ.CustomerId,
			EQ.MasterCompanyId,
			EQP.ExchangeQuotePartId,
			EQP.ItemMasterId,
			IM.PartNumber,
			IM.PartDescription,
			EQ.OpenDate,
			EQ.CreatedDate,
			EQ.ApprovedDate,
			EQ.QuoteExpireDate,
			EQ.StatusChangeDate,
			EQP.StockLineId,

			(Cast(DBO.ConvertUTCtoLocal(EQA.InternalApprovedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS InternalApprovedDate, 
			EQA.InternalSentDate,
			InternalApprovedBy = ISNULL(APP.FirstName + ' ' + APP.LastName, ''),
        
			(Cast(DBO.ConvertUTCtoLocal(EQA.CustomerApprovedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS CustomerApprovedDate,
			EQA.CustomerSentDate,
			CustomerApprovedBy = ISNULL(CON.FirstName + ' ' + CON.LastName, ''),

			EQA.RejectedById,
			(Cast(DBO.ConvertUTCtoLocal(EQA.RejectedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS RejectedDate,
			EQA.RejectedByName,
			EQA.ExchangeQuoteApprovalId,
			EQA.InternalApprovedById,
			EQA.CustomerApprovedById,
			EQA.InternalMemo,
			EQA.CustomerMemo,

			(Cast(DBO.ConvertUTCtoLocal(EQA.InternalRejectedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) AS InternalRejectedDate,
			internalRejectedBy = ISNULL(INTR.FirstName + ' ' + INTR.LastName, ''),
			EQA.InternalRejectedById,

			EQA.CreatedBy,
			EQA.UpdatedBy,
			UpdatedDate = ISNULL(EQA.UpdatedDate, GETDATE()),

			IsActive = 1,
			IsDeleted = 0,

			EQA.ApprovalActionId,
			EQ.IsEnforceApproval,
			EQ.EnforceEffectiveDate,
			EQA.InternalStatusId,

			CustomerStatusId = ISNULL(EQA.CustomerStatusId, @PendingApprovalStatusId),
			IsInternalApprove = @InternalApprove,

			EQA.InternalSentToId,
			EQA.InternalSentToName,
			EQA.InternalSentById

		FROM [dbo].[ExchangeQuote] EQ WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeQuotePart] EQP WITH(NOLOCK) ON EQ.ExchangeQuoteId = EQP.ExchangeQuoteId AND ISNULL(EQP.IsDeleted,0) = 0
		LEFT JOIN [dbo].[ExchangeQuoteApproval] EQA WITH(NOLOCK) ON EQP.ExchangeQuotePartId = EQA.ExchangeQuotePartId
		LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON EQP.ItemMasterId = IM.ItemMasterId
		LEFT JOIN [dbo].[Employee] APP WITH(NOLOCK) ON EQA.InternalApprovedById = APP.EmployeeId
		LEFT JOIN [dbo].[Contact] CON WITH(NOLOCK) ON EQA.CustomerApprovedById = CON.ContactId
		LEFT JOIN [dbo].[Employee] INTR WITH(NOLOCK) ON EQA.InternalRejectedById = INTR.EmployeeId
		WHERE EQ.ExchangeQuoteId = @ExchangeQuoteId AND ISNULL(EQ.IsDeleted,0) = 0;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteFreightAuditByFreightId'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeQuoteId = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS VARCHAR(100)) +''','+
												   '@InternalApprove = ''' + CAST(ISNULL(@InternalApprove, '') AS VARCHAR(100)) +''','+
												   '@EmployeeId = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
		RETURN(1);
	END CATCH
END
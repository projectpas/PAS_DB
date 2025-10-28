/*************************************************************           
 ** File:		  [dbo].[USP_Getexchangeloan]           
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used for get Data of ItemMasterexchangeloan
 ** Purpose:         
 ** Date:   26-09-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 26-09-2025			Nakul Chandigra		CREATED
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_Getexchangeloan]
@Id BIGINT,
@EmpId BIGINT
AS
BEGIN

	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmpId; 
		
	BEGIN TRY
	
	SELECT
		iME.itemMasterLoanExchId,
        iME.CreatedBy,
        CASE WHEN CAST(iME.CreatedDate AS DATE) = CAST('0001-01-01' AS DATE)  THEN NULL  ELSE CAST(DBO.ConvertUTCtoLocal(iME.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END AS CreatedDate,
        iME.ExchangeCoreCost,
        iME.ExchangeCorePrice,
        iME.ExchangeCurrencyId,
        iME.ExchangeListPrice,
        iME.ExchangeOutrightPrice,
        iME.ExchangeOverhaulPrice,
        iME.IsActive,
        iME.IsDeleted,
        iME.IsExchange,
        iME.IsLoan,
        iME.ItemMasterId,
        iME.ItemMasterLoanExchId,
        iME.LoanCorePrice,
        iME.LoanCurrencyId,
        iME.LoanFees,
        iME.LoanOutrightPrice,
        iME.MasterCompanyId,
        iME.UpdatedBy,
        CASE WHEN CAST(iME.UpdatedDate AS DATE) = CAST('0001-01-01' AS DATE) THEN NULL ELSE CAST(DBO.ConvertUTCtoLocal(iME.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) END AS UpdatedDate,
        ISNULL(ecu.Code, '') AS ExchangeCurrencyName,
        ISNULL(lcu.Code, '') AS LoanCurrencyName,
        iME.ExchangeOverhaulCost,
        iME.EFcogs AS efcogs,
        iME.OPcogs AS opcogs,
        iME.EFcogsamount AS efcogsamount,
        iME.OPcogsamount AS opcogsamount,
        ISNULL(pctef.PercentValue, 0) AS efcogsValue,
        ISNULL(pctoh.PercentValue, 0) AS opcogsValue
    FROM [DBO].[ItemMasterExchangeLoan] iME WITH (NOLOCK)
    LEFT JOIN [DBO].[Currency] ecu WITH (NOLOCK) ON iME.ExchangeCurrencyId = ecu.CurrencyId
    LEFT JOIN [DBO].[Currency] lcu WITH (NOLOCK) ON iME.LoanCurrencyId = lcu.CurrencyId
    LEFT JOIN [DBO].[Percent] pctef WITH (NOLOCK) ON iME.EFcogs = pctef.PercentId 
    LEFT JOIN [DBO].[Percent] pctoh WITH (NOLOCK) ON iME.OPcogs = pctoh.PercentId 
    WHERE iME.ItemMasterId = @Id
		AND iME.IsActive = 1
		AND iME.IsDeleted = 0;
	  
	END TRY 

	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = ' [dbo].[USP_Getexchangeloan]'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
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
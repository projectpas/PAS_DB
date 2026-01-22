/*************************************************************
 ** File:   [USP_GetExchangeSalesOrderChargesAuditDetails]
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetExchangeSalesOrderChargesAuditDetails
 ** Purpose:
 ** Date:   05/26/2025
    
 ** PARAMETERS: @ExchangeSalesOrderChargesId BIGINT

 ** RETURN VALUE:

 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------   
	1    05/26/2025   EKTA CHANDEGRA	Created
	

exec dbo.USP_GetExchangeSalesOrderChargesAuditDetails   @ExchangeSalesOrderChargesId=74
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeSalesOrderChargesAuditDetails]
    @ExchangeSalesOrderChargesId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @TMBillingMethodId BIGINT,@ActualBillingMethodId BIGINT, @FlateRateBillingMethodId BIGINT;

		SELECT  @TMBillingMethodId = BillingMethodId from BillingMethod WHERE Description = 'T&M' 
		SELECT  @ActualBillingMethodId = BillingMethodId from BillingMethod WHERE Description = 'Actual' 
		SELECT  @FlateRateBillingMethodId = BillingMethodId from BillingMethod WHERE Description = 'Flate Rate' 
		
		SELECT DISTINCT
			soc.AuditExchangeSalesOrderChargesId,
			soc.ExchangeSalesOrderChargesId,
			soc.ExchangeSalesOrderId,
			ISNULL(soc.ExchangeSalesOrderPartId,0) AS ExchangeSalesOrderPartId,
			soc.ChargesTypeId,
			ct.ChargeType,
			soc.Description,
			soc.Quantity,
			soc.UnitCost,
			soc.ExtendedCost,
			soc.MarkupFixedPrice,
			ISNULL(soc.VendorId,0) AS VendorId,
			ISNULL(soc.VendorName,'') AS VendorName,	
			soc.BillingMethodId,
			BillingMethodName = 
				CASE soc.BillingMethodId
					WHEN @TMBillingMethodId THEN 'TM'      
					WHEN @ActualBillingMethodId THEN 'Actual'   
					ELSE ''
				END,
			soc.BillingRate,
			soc.BillingAmount,
			soc.MarkupPercentageId,
			soc.CreatedBy,
			soc.CreatedDate,
			ISNULL(soc.IsActive,0) AS IsActive,
			ISNULL(soc.IsDeleted,0) AS IsDeleted,
			soc.MasterCompanyId,
			soc.HeaderMarkupId,
			soc.HeaderMarkupPercentageId,
			soc.UpdatedBy,
			soc.UpdatedDate,
			ISNULL(soc.RefNum,'') AS RefNum,
			ISNULL(gl.AccountName, '') AS GLAccountName
		FROM [dbo].[ExchangeSalesOrderChargesAudit] soc WITH(NOLOCK)
		INNER JOIN [dbo].[Charge] ct WITH(NOLOCK) ON soc.ChargesTypeId = ct.ChargeId
		LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		WHERE soc.ExchangeSalesOrderChargesId = @ExchangeSalesOrderChargesId
		ORDER BY soc.AuditExchangeSalesOrderChargesId DESC;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeSalesOrderChargesAuditDetails'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@ExchangeSalesOrderChargesId AS varchar(10)) ,'') +''

        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END
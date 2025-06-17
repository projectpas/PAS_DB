/*************************************************************           
 ** File:   [USP_GetExchangeSalesOrderHypoAnalysisList]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetExchangeSalesOrderHypoAnalysisList
 ** Purpose:         
 ** Date:    06/03/2025  

 ** PARAMETERS: @ExchangeSalesOrderId BIGINT 

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    06/03/2025  EKTA CHANDEGRA    Created
    2    06/16/2025  EKTA CHANDEGRA    Retrieve billing amount as OtherCharges and ExtendedCost as OtherCost
	     
 EXEC USP_GetExchangeSalesOrderHypoAnalysisList @ExchangeSalesOrderId = 176
************************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetExchangeSalesOrderHypoAnalysisList]
    @ExchangeSalesOrderId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @MasterCompanyId INT;
		DECLARE @COGSValue DECIMAL(18, 2);
		DECLARE @Charges DECIMAL(18, 2);
		DECLARE @OtherCharges DECIMAL(18, 2);
		DECLARE @ExchangeBillingTypeId INT;

		-- Get ExchangeSalesOrder data
		SELECT @MasterCompanyId = MasterCompanyId
		FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;


		-- Get COGS Percent
		SELECT @COGSValue = ISNULL(p.PercentValue, 0)
		FROM [dbo].[ExchangeSalesOrderSettings] es WITH(NOLOCK)
		LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON es.COGS = p.PercentId
		WHERE es.MasterCompanyId = @MasterCompanyId;

		-- Initial Charges and Other Charges
		SELECT TOP 1
			@Charges = ISNULL(BillingAmount, 0),
			@OtherCharges = ISNULL(ExtendedCost, 0)
		FROM [dbo].[ExchangeSalesOrderCharges] WITH(NOLOCK)
		WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId
		  AND ISNULL(IsActive,0) = 1
		  AND ISNULL(IsDeleted,0) = 0;

		-- If OtherCharges = 0, try fallback from active charges
		IF @OtherCharges = 0
		BEGIN
			SELECT TOP 1
				@OtherCharges = ISNULL(ExtendedCost, 0),
				@Charges = ISNULL(BillingAmount, 0)
			FROM [dbo].[ExchangeSalesOrderCharges] WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId
			  AND ISNULL(IsActive,0) = 1;
		END

		-- If flat rate, override both charges
		IF EXISTS (SELECT 1 FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK) WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId AND IsChargeFlatRate = 1)
		BEGIN
			SELECT @Charges = ChargeFlatRate, @OtherCharges = ChargeFlatRate
			FROM [dbo].[ExchangeSalesOrder] WITH(NOLOCK)
			WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId;
		END

		SELECT @ExchangeBillingTypeId = ExchangeBillingTypeId FROM [dbo].[ExchangeBillingType] WHERE Description = 'EXCH FEE';

		-- Final Output Query
		SELECT DISTINCT
			esop.ExchangeSalesOrderId,
			ISNULL((
				SELECT SUM(PeriodicBillingAmount)
				FROM [dbo].[ExchangeSalesOrderScheduleBilling] WITH(NOLOCK)
				WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId
				  AND IsPartEntry = 0
				  AND BillingTypeId = @ExchangeBillingTypeId
			), 0) AS ExchangeFees,
			esop.ExchangeOverhaulPrice,
			@Charges AS OtherCharges,
			ISNULL((
				SELECT SUM(PeriodicBillingAmount)
				FROM [dbo].[ExchangeSalesOrderScheduleBilling] WITH(NOLOCK)
				WHERE ExchangeSalesOrderId = @ExchangeSalesOrderId
				  AND IsPartEntry = 0
				  AND BillingTypeId = @ExchangeBillingTypeId
			), 0) + esop.ExchangeOverhaulPrice + @Charges AS TotalEstRevenue,
			ISNULL(esop.ExchangeOverhaulCost, 0) AS OverhaulCost,
			@OtherCharges AS OtherCost,
			esop.ExchangeListPrice AS ExchFees,
			ISNULL(epc.PercentValue, 0) AS ExchFeesCOGS,
			ISNULL(opc.PercentValue, 0) AS OverHaulCOGS,
			esop.EstOfFeeBilling
		FROM [dbo].[ExchangeSalesOrderPart] esop WITH(NOLOCK)
		LEFT JOIN [dbo].[ExchangeSalesOrderScheduleBilling] esos WITH(NOLOCK)
			ON esop.ExchangeSalesOrderId = esos.ExchangeSalesOrderId AND esos.IsPartEntry = 0
		LEFT JOIN [dbo].[ItemMasterExchangeLoan] ime WITH(NOLOCK)
			ON esop.ItemMasterId = ime.ItemMasterId
		LEFT JOIN [dbo].[Percent] epc WITH(NOLOCK)
			ON ime.EFcogs = epc.PercentId
		LEFT JOIN [dbo].[Percent] opc WITH(NOLOCK)
			ON ime.OPcogs = opc.PercentId
		WHERE esop.ExchangeSalesOrderId = @ExchangeSalesOrderId
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeSalesOrderHypoAnalysisList'     
			, @ProcedureParameters VARCHAR(3000) = '@ExchangeSalesOrderId = ''' + CAST(ISNULL(@ExchangeSalesOrderId, '') AS VARCHAR(100))
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
END;
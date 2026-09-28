
/*************************************************************           
 ** File:        [dbo].[USP_Addupdateexchangeloan]            
 ** Author:      Nakul Chandigra
 ** Description: This stored procedure is used to Add And Update exchangeloan
 ** Purpose:       
 ** Date:        
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author             Change Description            
 ** --   ----------  -----------------  -----------------------------         
 **  1   17-09-2025   Nakul Chandigra    Created 
 **  2   01-May-2025   Nakul Chandigra   Added ExchangeOutrightPrice While Update [PN-16021 ]
 **  3   28-09-2026	  Amit Ghediya		 Added for Lease [PN-18048]
 ************************************************************************/
CREATE     PROCEDURE [dbo].[USP_Addupdateexchangeloan] 
	@tbl_AddexchangeloanType dbo.AddexchangeloanType READONLY 
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;
    BEGIN TRY
    BEGIN TRANSACTION;

	DECLARE @ItemMasterLoanExchId BIGINT;
	DECLARE @ID BIGINT;

	SELECT @ID = ItemMasterLoanExchId 
	FROM @tbl_AddexchangeloanType;

	IF EXISTS (SELECT 1 
			   FROM [DBO].[ItemMasterExchangeLoan] 
			   WHERE ItemMasterLoanExchId = @ID)
	BEGIN

		UPDATE T 
		SET
			 T.ItemMasterId				=	S.ItemMasterId
			,T.IsLoan					=	S.IsLoan
			,T.IsExchange				=	S.IsExchange
			,T.ExchangeCurrencyId		=	S.ExchangeCurrencyId
			,T.LoanCurrencyId			=	S.LoanCurrencyId
			,T.ExchangeListPrice		=	S.ExchangeListPrice
			,T.ExchangeCorePrice		=	S.ExchangeCorePrice
			,T.ExchangeOverhaulPrice	=	S.ExchangeOverhaulPrice
			,T.ExchangeCoreCost			=	S.ExchangeCoreCost
			,T.LoanCorePrice			=	S.LoanCorePrice
			,T.LoanOutrightPrice		=	S.LoanOutrightPrice
			,T.LoanFees					=	S.LoanFees
			,T.MasterCompanyId			=	S.MasterCompanyId
			,T.CreatedBy				=	S.CreatedBy
			,T.CreatedDate				=	S.CreatedDate
			,T.UpdatedBy				=	S.UpdatedBy
			,T.UpdatedDatE				=	S.UpdatedDate
			,T.IsActive					=	S.IsActive
			,T.IsDeleted				=	S.IsDeleted
			,T.ExchangeOverhaulCost		=	S.ExchangeOverhaulCost
			,T.ExchangeOutrightPrice    = S.ExchangeOutrightPrice
			,T.EFcogs					=	S.EFcogs
			,T.OPcogs					=	S.OPcogs
			,T.EFcogsamount				=	S.EFcogsamount
			,T.OPcogsamount				=	S.OPcogsamount
			,T.IsFinanceLease					=	S.IsFinanceLease
			,T.FinanceLeaseCurrencyId			=	S.FinanceLeaseCurrencyId
			,T.IsOutrightSale					=	S.IsOutrightSale
			,T.FinanceLeaseOutrightPrice		=	S.FinanceLeaseOutrightPrice
			,T.IsFlatRate						=	S.IsFlatRate
			,T.FinanceLeaseFlatRate				=	S.FinanceLeaseFlatRate
			,T.FinanceLeaseRateUnit				=	S.FinanceLeaseRateUnit
			,T.FinanceLeaseBillingMethod		=	S.FinanceLeaseBillingMethod
			,T.FinanceLeaseBillingInterval		=	S.FinanceLeaseBillingInterval
			,T.FinanceLeaseMinimumCycles		=	S.FinanceLeaseMinimumCycles
			,T.FinanceLeaseMinimumTimes		=	S.FinanceLeaseMinimumTimes
			,T.FinanceLeaseMaximumCycles		=	S.FinanceLeaseMaximumCycles
			,T.FinanceLeaseMaximumTimes		=	S.FinanceLeaseMaximumTimes
			,T.FinanceLeaseUsagePerUnitCycles	=	S.FinanceLeaseUsagePerUnitCycles
			,T.FinanceLeaseUsagePerUnitTimes	=	S.FinanceLeaseUsagePerUnitTimes
			,T.FinanceLeaseOverrunPerUnitCycles	=	S.FinanceLeaseOverrunPerUnitCycles
			,T.FinanceLeaseOverrunPerUnitTimes	=	S.FinanceLeaseOverrunPerUnitTimes
			FROM [DBO].ItemMasterExchangeLoan  T
			INNER JOIN  @tbl_AddexchangeloanType S
			ON T.ItemMasterLoanExchId = @ID;
	END 

	ELSE 
	BEGIN

		INSERT INTO [DBO].[ItemMasterExchangeLoan]
		(
				[ItemMasterId],[IsLoan]  ,[IsExchange]  ,[ExchangeCurrencyId]  ,[LoanCurrencyId] ,[ExchangeListPrice],[ExchangeCorePrice] ,[ExchangeOverhaulPrice],[ExchangeOutrightPrice] ,[ExchangeCoreCost],[LoanCorePrice] ,
				[LoanOutrightPrice],[LoanFees] ,[MasterCompanyId]  ,[CreatedBy]  ,[CreatedDate]  ,[UpdatedBy]  ,[UpdatedDate]  ,[IsActive] ,[IsDeleted]  ,[ExchangeOverhaulCost] ,[EFcogs]  ,[OPcogs]  ,[EFcogsamount] ,[OPcogsamount] ,
				[IsFinanceLease],[FinanceLeaseCurrencyId],[IsOutrightSale],[FinanceLeaseOutrightPrice],[IsFlatRate],[FinanceLeaseFlatRate],[FinanceLeaseRateUnit],[FinanceLeaseBillingMethod],[FinanceLeaseBillingInterval],[FinanceLeaseMinimumCycles],[FinanceLeaseMinimumTimes],[FinanceLeaseMaximumCycles],[FinanceLeaseMaximumTimes],[FinanceLeaseUsagePerUnitCycles],[FinanceLeaseUsagePerUnitTimes],[FinanceLeaseOverrunPerUnitCycles],[FinanceLeaseOverrunPerUnitTimes]
		)
		SELECT
				[ItemMasterId],[IsLoan]  ,[IsExchange]  ,[ExchangeCurrencyId]  ,[LoanCurrencyId] ,[ExchangeListPrice],[ExchangeCorePrice] ,[ExchangeOverhaulPrice],[ExchangeOutrightPrice] ,[ExchangeCoreCost],[LoanCorePrice] ,
				[LoanOutrightPrice],[LoanFees] ,[MasterCompanyId]  ,[CreatedBy]  , GETUTCDATE() ,[UpdatedBy]  ,GETUTCDATE()  ,[IsActive] ,[IsDeleted]  ,[ExchangeOverhaulCost] ,[EFcogs]  ,[OPcogs]  ,[EFcogsamount] ,[OPcogsamount] ,
				[IsFinanceLease],[FinanceLeaseCurrencyId],[IsOutrightSale],[FinanceLeaseOutrightPrice],[IsFlatRate],[FinanceLeaseFlatRate],[FinanceLeaseRateUnit],[FinanceLeaseBillingMethod],[FinanceLeaseBillingInterval],[FinanceLeaseMinimumCycles],[FinanceLeaseMinimumTimes],[FinanceLeaseMaximumCycles],[FinanceLeaseMaximumTimes],[FinanceLeaseUsagePerUnitCycles],[FinanceLeaseUsagePerUnitTimes],[FinanceLeaseOverrunPerUnitCycles],[FinanceLeaseOverrunPerUnitTimes]
		FROM @tbl_AddexchangeloanType ael


		SET @ItemMasterLoanExchId = SCOPE_IDENTITY()  

		SELECT 	[ItemMasterLoanExchId],[ItemMasterId],[IsLoan]  ,[IsExchange]  ,[ExchangeCurrencyId]  ,[LoanCurrencyId] ,[ExchangeListPrice],[ExchangeCorePrice] ,[ExchangeOverhaulPrice],[ExchangeOutrightPrice] ,[ExchangeCoreCost],[LoanCorePrice] ,
				[LoanOutrightPrice],[LoanFees] ,[MasterCompanyId]  ,[CreatedBy]  ,[CreatedDate]  ,[UpdatedBy]  ,[UpdatedDate]  ,[IsActive] ,[IsDeleted]  ,[ExchangeOverhaulCost] ,[EFcogs]  ,[OPcogs]  ,[EFcogsamount] ,[OPcogsamount] ,
				[IsFinanceLease],[FinanceLeaseCurrencyId],[IsOutrightSale],[FinanceLeaseOutrightPrice],[IsFlatRate],[FinanceLeaseFlatRate],[FinanceLeaseRateUnit],[FinanceLeaseBillingMethod],[FinanceLeaseBillingInterval],[FinanceLeaseMinimumCycles],[FinanceLeaseMinimumTimes],[FinanceLeaseMaximumCycles],[FinanceLeaseMaximumTimes],[FinanceLeaseUsagePerUnitCycles],[FinanceLeaseUsagePerUnitTimes],[FinanceLeaseOverrunPerUnitCycles],[FinanceLeaseOverrunPerUnitTimes]
		FROM [DBO].[ItemMasterExchangeLoan] WITH(NOLOCK)
		WHERE [ItemMasterLoanExchId] = @ItemMasterLoanExchId

	END 
	COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				, @AdhocComments     VARCHAR(150)    = '[dbo].[USP_Addupdateexchangeloan] ' 
				, @ProcedureParameters VARCHAR(3000)  = ''
				, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
					exec spLogException 
							  @DatabaseName         = @DatabaseName
							, @AdhocComments        = @AdhocComments
							, @ProcedureParameters  = @ProcedureParameters
							, @ApplicationName      =  @ApplicationName
							, @ErrorLogID           = @ErrorLogID OUTPUT ;
					RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				RETURN(1);
	END CATCH
END
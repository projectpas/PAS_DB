/*************************************************************           
 ** File:   [USP_GetExchangeQuoteSettingList]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to USP_GetExchangeQuoteSettingList
 ** Purpose:         
 ** Date:   07/04/2025      
          
 ** PARAMETERS:  @MasterCompanyId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    07/04/2025   Ekta Chandegra     Created
     
  EXEC USP_GetExchangeQuoteSettingList @MasterCompanyId = 1

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeQuoteSettingList]
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

	BEGIN TRY
		DECLARE 
			@COGS INT = 0,
			@DaysForCoreReturn INT = 0,
			@FeesBillingIntervalDays INT = 0,
			@ExpectedConditionId BIGINT = 0;

		-- Step 1: Get data from ExchangeSalesOrderSettings
		SELECT TOP 1
			@COGS = COGS,
			@DaysForCoreReturn = DaysForCoreReturn,
			@FeesBillingIntervalDays = ISNULL(FeesBillingIntervalDays, 0),
			@ExpectedConditionId = ISNULL(ExpectedConditionId, 0)
		FROM [dbo].[ExchangeSalesOrderSettings] WITH(NOLOCK)
		WHERE ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1 AND MasterCompanyId = @MasterCompanyId;

		-- Step 2: Get ExchangeQuoteSetting List
		SELECT 
			eqs.ExchangeQuoteSettingId,
			eqs.Typeid,
			et.Name AS TypeName,
			eqs.Prefix,
			eqs.Sufix,
			eqs.StartCode,
			eqs.CurrentNumber,
			eqs.DefaultStatusId,
			es.Name AS DefaultStatusName,
			eqs.DefaultPriorityId,
			p.Description AS DefaultPriorityName,
			ISNULL(@COGS,0) AS COGS,
			ISNULL(@DaysForCoreReturn,0) AS DaysForCoreReturn,
			ISNULL(eqs.IsActive,0) AS IsActive,
			ISNULL(eqs.IsDeleted,0) AS IsDeleted,
			eqs.CreatedBy,
			eqs.CreatedDate,
			eqs.ValidDays,
			eqs.IsApprovalRule,
			eqs.EffectiveDate,
			ISNULL(@COGS,0) AS COGSvalue,
			ISNULL(@FeesBillingIntervalDays,0) AS FeesBillingIntervalDays,
			@ExpectedConditionId AS ExpectedConditionId
		FROM [dbo].[ExchangeQuoteSetting] eqs WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeType] et WITH(NOLOCK) ON eqs.Typeid = et.Id
		INNER JOIN [dbo].[ExchangeStatus] es WITH(NOLOCK) ON eqs.DefaultStatusId = es.ExchangeStatusId
		INNER JOIN [dbo].[Priority] p WITH(NOLOCK) ON eqs.DefaultPriorityId = p.PriorityId
		WHERE ISNULL(eqs.IsDeleted,0) = 0 AND ISNULL(eqs.IsActive,0) = 1 AND eqs.MasterCompanyId = @MasterCompanyId
		ORDER BY eqs.CreatedDate DESC;
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeQuoteSettingList'     
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
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
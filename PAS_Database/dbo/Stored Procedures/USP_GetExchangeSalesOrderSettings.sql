/*************************************************************
 ** File:   [USP_GetExchangeSalesOrderSettings]
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to USP_GetExchangeSalesOrderSettings
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
	

exec dbo.USP_GetExchangeSalesOrderSettings   @MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExchangeSalesOrderSettings]
    @MasterCompanyId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
			st.ExchangeSalesOrderSettingId,
			st.TypeId,
			qty.Name AS TypeName,
			ISNULL(st.Prefix,'') AS Prefix,
			ISNULL(st.Sufix,'') AS Sufix,
			st.StartCode,
			st.CurrentNumber,
			st.DefaultStatusId,
			ds.Name AS DefaultStatusName,
			st.DefaultPriorityId,
			pr.Description AS DefaultPriorityName,
			st.COGS,
			st.DaysForCoreReturn,
			ISNULL(st.IsActive,0) AS IsActive,
			ISNULL(st.IsDeleted,0) AS IsDeleted,
			st.CreatedBy,
			st.CreatedDate,
			st.ValidDays,
			st.TypeId AS TypeId,
			st.COGS AS COGSvalue,
			st.FeesBillingIntervalDays,
			st.ExpectedConditionId
		FROM [dbo].[ExchangeSalesOrderSettings] st WITH(NOLOCK)
		INNER JOIN [dbo].[ExchangeType] qty WITH(NOLOCK) ON st.TypeId = qty.Id
		INNER JOIN [dbo].[ExchangeStatus] ds WITH(NOLOCK) ON st.DefaultStatusId = ds.ExchangeStatusId
		INNER JOIN [dbo].[Priority] pr WITH(NOLOCK) ON st.DefaultPriorityId = pr.PriorityId
		WHERE ISNULL(st.IsDeleted,0) = 0
		  AND ISNULL(st.IsActive,0) = 1
		  AND st.MasterCompanyId = @MasterCompanyId
		ORDER BY st.CreatedDate DESC;
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_GetExchangeSalesOrderSettings'
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@MasterCompanyId AS varchar(10)) ,'') +''

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
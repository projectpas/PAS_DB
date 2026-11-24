
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderQuoteLabor]
 ** Author: Moin Bloch
 ** Description: 4.26 Labor lines of the quoted parts of the quotes on one page, as on the PAS quote Labor tab
 **              (USP_GetLaborListDetailsByWorkOrderQuoteDetailsId: the lines of the part's labor header).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorderquotes (MPN[].labor)
 ** Date:   18/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    18/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetWorkOrderQuoteLabor] @MasterCompanyId = 1, @WorkOrderQuoteIds = '1'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderQuoteLabor]
    @MasterCompanyId   INT,
    @WorkOrderQuoteIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            D.[WorkOrderQuoteDetailsId],   -- used by the API to attach the labor to its quoted part; not returned to clients
            NULLIF(LTRIM(RTRIM(L.[TaskName])), '') AS [Task],
            NULLIF(LTRIM(RTRIM(L.[Expertise])), '') AS [Expertise],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(E.[FirstName])), ''), NULLIF(LTRIM(RTRIM(E.[LastName])), '')) AS [Employee],
            NULLIF(LTRIM(RTRIM(L.[Billabletype])), '') AS [Billable],
            ISNULL(L.[Hours], 0) AS [Hours],
            L.[DirectLaborOHCost] AS [DirectLaborCost],
            L.[BurdenRateAmount],
            L.[TotalCostPerHour],
            L.[TotalCost],
            REPLACE(BM.[Description], 'Flate Rate', 'Flat Rate') AS [BillingMethod],   -- PAS stores 'Flate Rate'
            L.[BillingRate],
            L.[BillingAmount]
        FROM [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK)
        INNER JOIN [dbo].[WorkOrderQuote] Q WITH (NOLOCK)
            ON Q.[WorkOrderQuoteId] = D.[WorkOrderQuoteId] AND Q.[MasterCompanyId] = @MasterCompanyId AND ISNULL(Q.[IsDeleted], 0) = 0
        CROSS APPLY (SELECT TOP (1) H.[WorkOrderQuoteLaborHeaderId] FROM [dbo].[WorkOrderQuoteLaborHeader] H WITH (NOLOCK)
                     WHERE H.[WorkOrderQuoteDetailsId] = D.[WorkOrderQuoteDetailsId] AND H.[IsDeleted] = 0
                     ORDER BY H.[WorkOrderQuoteLaborHeaderId]) H
        INNER JOIN [dbo].[WorkOrderQuoteLabor] L WITH (NOLOCK)
            ON L.[WorkOrderQuoteLaborHeaderId] = H.[WorkOrderQuoteLaborHeaderId] AND ISNULL(L.[IsDeleted], 0) = 0
        LEFT JOIN [dbo].[Employee] E WITH (NOLOCK) ON E.[EmployeeId] = L.[EmployeeId]
        LEFT JOIN [dbo].[BillingMethod] BM WITH (NOLOCK) ON BM.[BillingMethodId] = L.[BillingMethodId]
        WHERE D.[WorkOrderQuoteId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderQuoteIds, ','))
          AND ISNULL(D.[IsDeleted], 0) = 0
          AND ISNULL(D.[IsActive], 1) = 1
        ORDER BY D.[WorkOrderQuoteDetailsId], L.[WorkOrderQuoteLaborId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetWorkOrderQuoteLabor'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderQuoteIds, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END
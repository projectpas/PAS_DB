
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderList]
 ** Author: Moin Bloch
 ** Description: 4.13 GET /api/v1/workorders. WO headers of the company, oldest first. @Status is the WO status (Open, Closed, Canceled, Pending,
 **              Approved, Delayed, Received, Delayed-Cust).
 **              @OpenDateFrom / @OpenDateTo: open date range, both inclusive (dates only).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorders (headers)
 ** Date:   12/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/11/2026   Moin Bloch    Created
    2    18/11/2026   Moin Bloch    Added open date filter (@OpenDateFrom / @OpenDateTo)
    3    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetWorkOrderList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT,
    @WorkOrderNumber VARCHAR(50) = NULL,
    @Status          VARCHAR(50) = NULL,
    @OpenDateFrom    DATE = NULL,
    @OpenDateTo      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        ;WITH PagedWO AS
        (
            SELECT WO.[WorkOrderId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[WorkOrder] WO WITH (NOLOCK)
            LEFT JOIN [dbo].[WorkOrderStatus] WS WITH (NOLOCK) ON WS.[Id] = WO.[WorkOrderStatusId]
            WHERE WO.[MasterCompanyId] = @MasterCompanyId
              AND WO.[IsDeleted] = 0
              AND ISNULL(WO.[IsMigrated], 0) <> 1
              AND (@WorkOrderNumber IS NULL OR WO.[WorkOrderNum] = @WorkOrderNumber)
              AND (@Status IS NULL OR WS.[Description] = @Status)
              AND (@OpenDateFrom IS NULL OR WO.[OpenDate] >= @OpenDateFrom)
              AND (@OpenDateTo IS NULL OR WO.[OpenDate] < DATEADD(DAY, 1, @OpenDateTo))
            ORDER BY WO.[WorkOrderId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            WO.[WorkOrderId],   -- used by the API to attach the parts; not returned to clients
            WO.[WorkOrderNum] AS [WorkOrderNumber],
            ISNULL(WT.[Description], WO.[WorkOrderType]) AS [WorkOrderType],
            WS.[Description] AS [Status],
            WO.[OpenDate],
            CAST(ISNULL(WO.[IsWarranty], 0) AS BIT) AS [IsWarranty],
            C.[CustomerCode],
            ISNULL(NULLIF(LTRIM(RTRIM(WO.[CustomerName])), ''), C.[Name]) AS [CustomerName],
            WO.[CustomerType],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(CT.[FirstName])), ''), NULLIF(LTRIM(RTRIM(CT.[LastName])), '')) AS [CustomerContact],
            CT.[WorkPhone] AS [CustomerContactPhone],
            CT.[Email] AS [CustomerContactEmail],
            WO.[CreditTerms],
            WO.[CreditLimit],
            FC.[Code] AS [FunctionalCurrency],
            RC.[Code] AS [ReportCurrency],
            CASE WHEN WO.[ForeignExchangeRate] > 0 THEN WO.[ForeignExchangeRate] ELSE NULL END AS [ForeignExchangeRate],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(SP.[FirstName])), ''), NULLIF(LTRIM(RTRIM(SP.[LastName])), '')) AS [SalesPerson],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(CSR.[FirstName])), ''), NULLIF(LTRIM(RTRIM(CSR.[LastName])), '')) AS [CustomerServiceRep],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(EMP.[FirstName])), ''), NULLIF(LTRIM(RTRIM(EMP.[LastName])), '')) AS [Employee],
            (SELECT COUNT(1) FROM [dbo].[WorkOrderPartNumber] P WITH (NOLOCK) WHERE P.[WorkOrderId] = WO.[WorkOrderId] AND P.[IsDeleted] = 0) AS [PartsCount],
            WO.[CreatedDate],
            WO.[UpdatedDate],
            W.[TotalRecords]
        FROM PagedWO W
        INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = W.[WorkOrderId]
        LEFT JOIN [dbo].[WorkOrderStatus] WS WITH (NOLOCK) ON WS.[Id] = WO.[WorkOrderStatusId]
        LEFT JOIN [dbo].[WorkOrderType] WT WITH (NOLOCK) ON WT.[Id] = WO.[WorkOrderTypeId]
        LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = WO.[CustomerId]
        LEFT JOIN [dbo].[CustomerContact] CC WITH (NOLOCK) ON CC.[CustomerContactId] = WO.[CustomerContactId]
        LEFT JOIN [dbo].[Contact] CT WITH (NOLOCK) ON CT.[ContactId] = CC.[ContactId]
        LEFT JOIN [dbo].[Employee] SP WITH (NOLOCK) ON SP.[EmployeeId] = WO.[SalesPersonId]
        LEFT JOIN [dbo].[Employee] CSR WITH (NOLOCK) ON CSR.[EmployeeId] = WO.[CSRId]
        LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK) ON EMP.[EmployeeId] = WO.[EmployeeId]
        LEFT JOIN [dbo].[Currency] FC WITH (NOLOCK) ON FC.[CurrencyId] = WO.[FunctionalCurrencyId]
        LEFT JOIN [dbo].[Currency] RC WITH (NOLOCK) ON RC.[CurrencyId] = WO.[ReportCurrencyId]
        ORDER BY WO.[WorkOrderId]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetWorkOrderList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@WorkOrderNumber, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@Status, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@OpenDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@OpenDateTo, '') AS VARCHAR(100))
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
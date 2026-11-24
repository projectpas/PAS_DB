/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderQuoteList]
 ** Author: Moin Bloch
 ** Description: 4.23 Quote headers of the company, oldest first. Same quotes as the PAS Work Order Quote list (GetWorkOrderQuoteList).
 **              @Status is the quote status (Open, Closed, Cancelled, Delayed, Approved, Pending).
 **              @OpenDateFrom / @OpenDateTo: open date range, both inclusive (dates only).
 **              QuoteDate = when the quote was entered in PAS; management structure = the first quoted part's.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorderquotes (headers)
 ** Date:   18/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    18/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)
    3    23/11/2026   Moin Bloch    Fields as requested (quote date, customer type, created by, management structure)

  EXEC [dbo].[USP_PublicApi_GetWorkOrderQuoteList] @MasterCompanyId = 1, @PageNumber = 1, @PageSize = 50
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderQuoteList]
    @MasterCompanyId INT,
    @PageNumber      INT,
    @PageSize        INT,
    @QuoteNumber     VARCHAR(50) = NULL,
    @WorkOrderNumber VARCHAR(50) = NULL,
    @Status          VARCHAR(50) = NULL,
    @OpenDateFrom    DATE = NULL,
    @OpenDateTo      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @WOMSModuleId INT = 12; -- WorkOrderMPN (WorkOrderManagementStructureDetails.ModuleID)

        ;WITH PagedQuote AS
        (
            SELECT Q.[WorkOrderQuoteId], COUNT(1) OVER () AS [TotalRecords]
            FROM [dbo].[WorkOrderQuote] Q WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = Q.[WorkOrderId]
            INNER JOIN [dbo].[WorkOrderQuoteStatus] QS WITH (NOLOCK) ON QS.[WorkOrderQuoteStatusId] = Q.[QuoteStatusId]
            WHERE Q.[MasterCompanyId] = @MasterCompanyId
              AND ISNULL(Q.[IsDeleted], 0) = 0
              AND (@QuoteNumber IS NULL OR Q.[QuoteNumber] = @QuoteNumber)
              AND (@WorkOrderNumber IS NULL OR WO.[WorkOrderNum] = @WorkOrderNumber)
              AND (@Status IS NULL OR QS.[Description] = @Status)
              AND (@OpenDateFrom IS NULL OR Q.[OpenDate] >= @OpenDateFrom)
              AND (@OpenDateTo IS NULL OR Q.[OpenDate] < DATEADD(DAY, 1, @OpenDateTo))
              -- Same quotes as the PAS list: an existing customer and WO status, and a stock part with a stage.
              AND EXISTS (SELECT 1 FROM [dbo].[Customer] C WITH (NOLOCK) WHERE C.[CustomerId] = Q.[CustomerId])
              AND EXISTS (SELECT 1 FROM [dbo].[WorkOrderStatus] WS WITH (NOLOCK) WHERE WS.[Id] = WO.[WorkOrderStatusId])
              AND EXISTS (SELECT 1 FROM [dbo].[WorkOrderPartNumber] P WITH (NOLOCK)
                          INNER JOIN [dbo].[WorkOrderStage] ST WITH (NOLOCK) ON ST.[WorkOrderStageId] = P.[WorkOrderStageId]
                          INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = P.[ItemMasterId]
                          WHERE P.[WorkOrderId] = Q.[WorkOrderId] AND ISNULL(IM.[IsNonStock], 0) = 0)
            ORDER BY Q.[WorkOrderQuoteId]
            OFFSET (@PageNumber - 1) * @PageSize ROWS
            FETCH NEXT @PageSize ROWS ONLY
        )
        SELECT
            Q.[WorkOrderQuoteId],   -- used by the API to attach the quoted parts; not returned to clients
            Q.[QuoteNumber],
            Q.[VersionNo] AS [VersionNumber],
            Q.[CreatedDate] AS [QuoteDate],   -- when the quote was entered in PAS
            Q.[OpenDate],
            QS.[Description] AS [Status],
            CT.[CustomerTypeName] AS [CustomerType],
            ISNULL(C.[Name], NULLIF(LTRIM(RTRIM(Q.[CustomerName])), '')) AS [CustomerName],   -- the customer's name, as the PAS list and print
            C.[CustomerCode],
            NULLIF(LTRIM(RTRIM(C.[ContractReference])), '') AS [CustomerReference],
            WO.[WorkOrderNum] AS [WorkOrderNumber],
            Q.[ApprovedDate],
            CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(SP.[FirstName])), ''), NULLIF(LTRIM(RTRIM(SP.[LastName])), '')) AS [SalesPerson],
            NULLIF(LTRIM(RTRIM(Q.[CreatedBy])), '') AS [CreatedBy],
            MS.[Level1Name] AS [LegalEntity],
            MS.[Level2Name] AS [BusinessUnit],
            MS.[Level3Name] AS [Division],
            MS.[Level4Name] AS [Department],
            (SELECT COUNT(1) FROM [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK)
             WHERE D.[WorkOrderQuoteId] = Q.[WorkOrderQuoteId] AND ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsActive], 1) = 1) AS [MPNCount],
            P.[TotalRecords]
        FROM PagedQuote P
        INNER JOIN [dbo].[WorkOrderQuote] Q WITH (NOLOCK) ON Q.[WorkOrderQuoteId] = P.[WorkOrderQuoteId]
        INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.[WorkOrderId] = Q.[WorkOrderId]
        INNER JOIN [dbo].[WorkOrderQuoteStatus] QS WITH (NOLOCK) ON QS.[WorkOrderQuoteStatusId] = Q.[QuoteStatusId]
        LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON C.[CustomerId] = Q.[CustomerId]
        LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON CT.[CustomerTypeId] = C.[CustomerTypeId]
        LEFT JOIN [dbo].[Employee] SP WITH (NOLOCK) ON SP.[EmployeeId] = COALESCE(Q.[SalesPersonId], WO.[SalesPersonId])
        -- Management structure of the first quoted part (the WO part's structure).
        OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name]
                     FROM [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK)
                     LEFT JOIN [dbo].[WorkOrderWorkFlow] WF WITH (NOLOCK) ON WF.[WorkFlowWorkOrderId] = D.[WorkflowWorkOrderId]
                     INNER JOIN [dbo].[WorkOrderManagementStructureDetails] M WITH (NOLOCK)
                         ON M.[ModuleID] = @WOMSModuleId AND M.[ReferenceID] = COALESCE(NULLIF(D.[WOPartNoId], 0), WF.[WorkOrderPartNoId])
                     WHERE D.[WorkOrderQuoteId] = Q.[WorkOrderQuoteId] AND ISNULL(D.[IsDeleted], 0) = 0 AND ISNULL(D.[IsActive], 1) = 1
                     ORDER BY D.[WorkOrderQuoteDetailsId], M.[MSDetailsId]) MS
        ORDER BY Q.[WorkOrderQuoteId]
        OPTION (RECOMPILE);
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetWorkOrderQuoteList'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@QuoteNumber, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@WorkOrderNumber, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@Status, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@OpenDateFrom, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@OpenDateTo, '') AS VARCHAR(100))
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
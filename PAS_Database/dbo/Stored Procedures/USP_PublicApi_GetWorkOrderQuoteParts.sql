
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderQuoteParts]
 ** Author: Moin Bloch
 ** Description: 4.24 Quoted parts (WorkOrderQuoteDetails) of the quotes on one page (@WorkOrderQuoteIds: comma separated).
 **              Billing per category is the amount PAS bills (GetWorkOrderQuoteDetailsForInvioce): the flat amount for
 **              Flat Rate, otherwise the revenue. IsCommonFlatRate (QuoteMethod = 1): the part is quoted at CommonFlatRate.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorderquotes (MPN)
 ** Date:   18/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    18/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetWorkOrderQuoteParts] @MasterCompanyId = 1, @WorkOrderQuoteIds = '1'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderQuoteParts]
    @MasterCompanyId   INT,
    @WorkOrderQuoteIds VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @FlatRate INT = 3; -- BillingMethod: 1 T&M, 2 Actual, 3 Flat Rate

        SELECT
            -- Ids are used by the API to group parts per quote and attach their lines; not returned to clients.
            D.[WorkOrderQuoteId],
            D.[WorkOrderQuoteDetailsId],
            ISNULL(NULLIF(P.[PartNumber], ''), IM.[partnumber]) AS [PartNumber],
            ISNULL(NULLIF(P.[PartDescription], ''), IM.[PartDescription]) AS [PartDescription],
            ISNULL(NULLIF(P.[ManufacturerName], ''), IM.[ManufacturerName]) AS [Manufacturer],
            P.[CurrentSerialNumber] AS [SerialNumber],
            CD.[Description] AS [Condition],
            P.[WorkScope],
            ISNULL(P.[Quantity], 0) AS [Quantity],
            CAST(CASE WHEN D.[QuoteMethod] = 1 THEN 1 ELSE 0 END AS BIT) AS [IsCommonFlatRate],
            D.[CommonFlatRate],
            D.[EvalFees] AS [EvaluationFees],
            -- PAS stores 'Flate Rate'; its screens show 'Flat Rate'.
            REPLACE(MBM.[Description], 'Flate Rate', 'Flat Rate') AS [MaterialBillingMethod],
            ISNULL(D.[MaterialCost], 0) AS [MaterialCost],
            CASE WHEN D.[MaterialBuildMethod] = @FlatRate THEN ISNULL(D.[MaterialFlatBillingAmount], 0) ELSE ISNULL(D.[MaterialRevenue], 0) END AS [MaterialBilling],
            ISNULL(D.[MaterialMargin], 0) AS [MaterialMargin],
            REPLACE(LBM.[Description], 'Flate Rate', 'Flat Rate') AS [LaborBillingMethod],
            ISNULL(D.[LaborHours], 0) AS [LaborHours],
            ISNULL(D.[LaborCost], 0) AS [LaborCost],
            CASE WHEN D.[LaborBuildMethod] = @FlatRate THEN ISNULL(D.[LaborFlatBillingAmount], 0) ELSE ISNULL(D.[LaborRevenue], 0) END AS [LaborBilling],
            ISNULL(D.[LaborMargin], 0) AS [LaborMargin],
            REPLACE(CBM.[Description], 'Flate Rate', 'Flat Rate') AS [ChargesBillingMethod],
            ISNULL(D.[ChargesCost], 0) AS [ChargesCost],
            CASE WHEN D.[ChargesBuildMethod] = @FlatRate THEN ISNULL(D.[ChargesFlatBillingAmount], 0) ELSE ISNULL(D.[ChargesRevenue], 0) END AS [ChargesBilling],
            ISNULL(D.[ChargesMargin], 0) AS [ChargesMargin],
            REPLACE(FBM.[Description], 'Flate Rate', 'Flat Rate') AS [FreightBillingMethod],
            ISNULL(D.[FreightCost], 0) AS [FreightCost],
            CASE WHEN D.[FreightBuildMethod] = @FlatRate THEN ISNULL(D.[FreightFlatBillingAmount], 0) ELSE ISNULL(D.[FreightRevenue], 0) END AS [FreightBilling],
            ISNULL(D.[ExclusionsCost], 0) AS [ExclusionsCost],
            ISNULL(D.[ExclusionsBilling], 0) AS [ExclusionsBilling]
        FROM [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK)
        INNER JOIN [dbo].[WorkOrderQuote] Q WITH (NOLOCK)
            ON Q.[WorkOrderQuoteId] = D.[WorkOrderQuoteId] AND Q.[MasterCompanyId] = @MasterCompanyId AND ISNULL(Q.[IsDeleted], 0) = 0
        LEFT JOIN [dbo].[WorkOrderWorkFlow] WF WITH (NOLOCK) ON WF.[WorkFlowWorkOrderId] = D.[WorkflowWorkOrderId]
        LEFT JOIN [dbo].[WorkOrderPartNumber] P WITH (NOLOCK) ON P.[ID] = COALESCE(NULLIF(D.[WOPartNoId], 0), WF.[WorkOrderPartNoId])
        LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = COALESCE(D.[ItemMasterId], P.[ItemMasterId])
        LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = P.[ConditionId]
        LEFT JOIN [dbo].[BillingMethod] MBM WITH (NOLOCK) ON MBM.[BillingMethodId] = D.[MaterialBuildMethod]
        LEFT JOIN [dbo].[BillingMethod] LBM WITH (NOLOCK) ON LBM.[BillingMethodId] = D.[LaborBuildMethod]
        LEFT JOIN [dbo].[BillingMethod] CBM WITH (NOLOCK) ON CBM.[BillingMethodId] = D.[ChargesBuildMethod]
        LEFT JOIN [dbo].[BillingMethod] FBM WITH (NOLOCK) ON FBM.[BillingMethodId] = D.[FreightBuildMethod]
        WHERE D.[WorkOrderQuoteId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderQuoteIds, ','))
          AND ISNULL(D.[IsDeleted], 0) = 0
          AND ISNULL(D.[IsActive], 1) = 1
        ORDER BY D.[WorkOrderQuoteId], D.[WorkOrderQuoteDetailsId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetWorkOrderQuoteParts'
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
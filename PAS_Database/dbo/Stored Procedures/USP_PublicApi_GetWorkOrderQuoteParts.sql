/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderQuoteParts]
 ** Author: Moin Bloch
 ** Description: 4.24 Quoted parts (WorkOrderQuoteDetails) of the quotes on one page (@WorkOrderQuoteIds: comma separated).
 **              Amounts as on the printed quote (RPT_GetWorkOrderQuotePrintPdfData, USP_GetCustomerTax_Information_Repair_WOQ):
 **                revenue per category = the flat amount for Flat Rate, otherwise the revenue; a part quoted at one common
 **                flat rate (QuoteMethod) shows the flat rate as material and 0 for labor, charges and freight;
 **                sales / other tax = (material + labor + charges) x the customer's repair tax rates for the primary
 **                ship-to site and the part's origin site (stockline site); QuoteAmount = material + labor + charges + taxes
 **                (the printed TOTAL; freight is shown separately and not added).
 **              UnitCost = (material + labor + charges + freight cost) / part quantity.
 **              ApprovedBy / CustomerApprovedBy: latest approval of the part (WorkOrderApproval), as the PAS approval tab.
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
    3    23/11/2026   Moin Bloch    Fields as requested (priority, unit cost, revenues, taxes and quote amount as printed, approvers)

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
            -- Ids are used by the API to group parts per quote; not returned to clients.
            D.[WorkOrderQuoteId],
            D.[WorkOrderQuoteDetailsId],
            ISNULL(NULLIF(P.[PartNumber], ''), IM.[partnumber]) AS [PartNumber],
            ISNULL(NULLIF(P.[PartDescription], ''), IM.[PartDescription]) AS [PartDescription],
            CD.[Description] AS [Condition],
            P.[WorkScope],
            ISNULL(NULLIF(LTRIM(RTRIM(P.[Priority])), ''), PR.[Description]) AS [Priority],
            ISNULL(P.[Quantity], 0) AS [Quantity],
            (ISNULL(D.[MaterialCost], 0) + ISNULL(D.[LaborCost], 0) + ISNULL(D.[ChargesCost], 0) + ISNULL(D.[FreightCost], 0)) / NULLIF(P.[Quantity], 0) AS [UnitCost],
            B.[MaterialRevenue],
            B.[LaborRevenue],
            B.[ChargesRevenue],
            B.[FreightRevenue],
            T.[SalesTax],
            T.[OtherTax],
            T.[TaxBase] + T.[SalesTax] + T.[OtherTax] AS [QuoteAmount],
            NULLIF(LTRIM(RTRIM(ISNULL(AE.[FirstName], '') + ' ' + ISNULL(AE.[LastName], ''))), '') AS [ApprovedBy],
            NULLIF(LTRIM(RTRIM(ISNULL(AC.[FirstName], '') + ' ' + ISNULL(AC.[LastName], ''))), '') AS [CustomerApprovedBy]
        FROM [dbo].[WorkOrderQuoteDetails] D WITH (NOLOCK)
        INNER JOIN [dbo].[WorkOrderQuote] Q WITH (NOLOCK)
            ON Q.[WorkOrderQuoteId] = D.[WorkOrderQuoteId] AND Q.[MasterCompanyId] = @MasterCompanyId AND ISNULL(Q.[IsDeleted], 0) = 0
        LEFT JOIN [dbo].[WorkOrderWorkFlow] WF WITH (NOLOCK) ON WF.[WorkFlowWorkOrderId] = D.[WorkflowWorkOrderId]
        LEFT JOIN [dbo].[WorkOrderPartNumber] P WITH (NOLOCK) ON P.[ID] = COALESCE(NULLIF(D.[WOPartNoId], 0), WF.[WorkOrderPartNoId])
        LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = COALESCE(D.[ItemMasterId], P.[ItemMasterId])
        LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = P.[ConditionId]
        LEFT JOIN [dbo].[Priority] PR WITH (NOLOCK) ON PR.[PriorityId] = P.[WorkOrderPriorityId]
        -- Revenue per category as printed: a common flat rate (QuoteMethod) is shown as material.
        CROSS APPLY (SELECT
            CASE WHEN ISNULL(D.[QuoteMethod], 0) > 0 THEN ISNULL(D.[CommonFlatRate], 0)
                 WHEN D.[MaterialBuildMethod] = @FlatRate THEN ISNULL(D.[MaterialFlatBillingAmount], 0) ELSE ISNULL(D.[MaterialRevenue], 0) END AS [MaterialRevenue],
            CASE WHEN ISNULL(D.[QuoteMethod], 0) > 0 THEN 0
                 WHEN D.[LaborBuildMethod] = @FlatRate THEN ISNULL(D.[LaborFlatBillingAmount], 0) ELSE ISNULL(D.[LaborRevenue], 0) END AS [LaborRevenue],
            CASE WHEN ISNULL(D.[QuoteMethod], 0) > 0 THEN 0
                 WHEN D.[ChargesBuildMethod] = @FlatRate THEN ISNULL(D.[ChargesFlatBillingAmount], 0) ELSE ISNULL(D.[ChargesRevenue], 0) END AS [ChargesRevenue],
            CASE WHEN ISNULL(D.[QuoteMethod], 0) > 0 THEN 0
                 WHEN D.[FreightBuildMethod] = @FlatRate THEN ISNULL(D.[FreightFlatBillingAmount], 0) ELSE ISNULL(D.[FreightRevenue], 0) END AS [FreightRevenue]) B
        -- Repair tax rates for the customer's primary ship-to site and the part's origin site, as USP_GetCustomerTax_Information_Repair.
        LEFT JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = P.[StockLineId]
        OUTER APPLY (SELECT TOP (1) CDS.[CustomerDomensticShippingId] FROM [dbo].[CustomerDomensticShipping] CDS WITH (NOLOCK)
                     WHERE CDS.[CustomerId] = Q.[CustomerId] AND CDS.[IsPrimary] = 1
                     ORDER BY CDS.[CustomerDomensticShippingId]) SHIP
        OUTER APPLY (SELECT SUM(CASE WHEN TT.[Code] = 'SALES TAX' THEN CAST(ISNULL(TR.[TaxRate], 0) AS DECIMAL(18, 2)) ELSE 0 END) AS [SalesRate],
                            SUM(CASE WHEN TT.[Code] = 'SALES TAX' THEN 0 ELSE CAST(ISNULL(TR.[TaxRate], 0) AS DECIMAL(18, 2)) END) AS [OtherRate]
                     FROM [dbo].[CustomerTaxTypeRateMapping] M WITH (NOLOCK)
                     INNER JOIN [dbo].[TaxType] TT WITH (NOLOCK) ON TT.[TaxTypeId] = M.[TaxTypeId]
                     INNER JOIN [dbo].[TaxRate] TR WITH (NOLOCK) ON TR.[TaxRateId] = M.[TaxRateId]
                     WHERE M.[CustomerId] = Q.[CustomerId] AND M.[SiteId] = SHIP.[CustomerDomensticShippingId] AND M.[ShipFromSiteId] = STK.[SiteId]
                       AND M.[IsRepair] = 1 AND M.[IsTaxExempt] = 0 AND M.[IsDeleted] = 0 AND M.[IsActive] = 1) R
        -- Taxed amount and taxes rounded to cents, as the print (DECIMAL(18,2) variables).
        CROSS APPLY (SELECT CAST(B.[MaterialRevenue] + B.[LaborRevenue] + B.[ChargesRevenue] AS DECIMAL(18, 2)) AS [TaxBase]) TB
        CROSS APPLY (SELECT TB.[TaxBase],
                            CAST(TB.[TaxBase] * ISNULL(R.[SalesRate], 0) / 100 AS DECIMAL(18, 2)) AS [SalesTax],
                            CAST(TB.[TaxBase] * ISNULL(R.[OtherRate], 0) / 100 AS DECIMAL(18, 2)) AS [OtherTax]) T
        -- Latest approval of the part on this quote: internal approver (employee), customer approver (customer contact).
        OUTER APPLY (SELECT TOP (1) A.[InternalApprovedById], A.[CustomerApprovedById]
                     FROM [dbo].[WorkOrderApproval] A WITH (NOLOCK)
                     WHERE A.[WorkOrderQuoteId] = D.[WorkOrderQuoteId] AND A.[WorkOrderPartNoId] = P.[ID] AND A.[IsDeleted] = 0
                     ORDER BY A.[WorkOrderApprovalId] DESC) AP
        LEFT JOIN [dbo].[Employee] AE WITH (NOLOCK) ON AE.[EmployeeId] = AP.[InternalApprovedById]
        LEFT JOIN [dbo].[Contact] AC WITH (NOLOCK) ON AC.[ContactId] = AP.[CustomerApprovedById]
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
/*************************************************************
 ** File:   [FleetQuoteDetailsType.sql]
 ** Author:  Kishor Makwana
 ** Description: Table-valued parameter type for the "header" row passed to
 **              each of the Aircraft / Fleet Quote build-up tabs' Create
 **              stored procedures (dbo.USP_CreateFleetQuoteMaterial /
 **              USP_CreateFleetQuoteLabor / USP_CreateFleetQuoteFreight /
 **              USP_CreateFleetQuoteCharges - PN-17707). Mirrors
 **              dbo.FleetQuoteDetails column-for-column (see
 **              PAS_Database\dbo\Tables\Tables2\FleetQuoteDetails.sql) -
 **              same convention as Work Order Quote's own
 **              @tbl_WorkOrderQuoteDetailsType TVP (built from the
 **              equivalent WorkOrderQuoteDetails-shaped woqDetails
 **              DataTable in WorkOrderRepository.CreateWorkOrderQuoteMaterial
 **              et al.) - one shared header type reused by all 4 Create
 **              procedures, always carrying exactly one row: the current
 **              state of the dbo.FleetQuoteDetails row the tab's grid is
 **              being saved under, so the Cost/Billing/Revenue/Margin
 **              rollup columns can be recalculated and persisted in the
 **              same transaction as the detail-line rows.
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17707]
 **************************************************************/
CREATE TYPE [dbo].[FleetQuoteDetailsType] AS TABLE (
    [FleetQuoteDetailsId]           BIGINT          NOT NULL,
    [FleetQuoteId]                  BIGINT          NOT NULL,
    [ItemMasterId]                  BIGINT          NOT NULL,
    [BuildMethodId]                 BIGINT          NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   NULL,
    [UpdatedDate]                   DATETIME2 (7)   NULL,
    [IsActive]                      BIT             NULL,
    [IsDeleted]                     BIT             NULL,
    [WorkflowWorkOrderId]           BIGINT          NULL,
    [WOPartNoId]                    BIGINT          NULL,
    [WorkOrderId]                   BIGINT          NULL,
    [MaterialCost]                  DECIMAL (18, 6) NULL,
    [MaterialBilling]               DECIMAL (18, 6) NULL,
    [MaterialRevenuePercentage]     DECIMAL (18, 6) NULL,
    [MaterialMargin]                DECIMAL (18, 6) NULL,
    [LaborHours]                    INT             NULL,
    [LaborCost]                     DECIMAL (18, 6) NULL,
    [LaborBilling]                  DECIMAL (18, 6) NULL,
    [LaborRevenuePercentage]        DECIMAL (18, 6) NULL,
    [LaborMargin]                   DECIMAL (18, 6) NULL,
    [ChargesCost]                   DECIMAL (18, 6) NULL,
    [ChargesBilling]                DECIMAL (18, 6) NULL,
    [ChargesRevenuePercentage]      DECIMAL (18, 6) NULL,
    [ChargesMargin]                 DECIMAL (18, 6) NULL,
    [ExclusionsCost]                DECIMAL (18, 6) NULL,
    [ExclusionsBilling]             DECIMAL (18, 6) NULL,
    [ExclusionsRevenuePercentage]   DECIMAL (18, 6) NULL,
    [ExclusionsMargin]              DECIMAL (18, 6) NULL,
    [FreightCost]                   DECIMAL (18, 6) NULL,
    [FreightBilling]                DECIMAL (18, 6) NULL,
    [FreightRevenuePercentage]      DECIMAL (18, 6) NULL,
    [FreightMargin]                 DECIMAL (18, 6) NULL,
    [MaterialMarginPer]             DECIMAL (18, 6) NULL,
    [LaborMarginPer]                DECIMAL (18, 6) NULL,
    [ChargesMarginPer]              DECIMAL (18, 6) NULL,
    [ExclusionsMarginPer]           DECIMAL (18, 6) NULL,
    [FreightMarginPer]              DECIMAL (18, 6) NULL,
    [OverHeadCost]                  DECIMAL (18, 6) NULL,
    [AdjustmentHours]               INT             NULL,
    [AdjustedHours]                 INT             NULL,
    [LaborFlatBillingAmount]        DECIMAL (18, 6) NULL,
    [MaterialFlatBillingAmount]     DECIMAL (18, 6) NULL,
    [ChargesFlatBillingAmount]      DECIMAL (18, 6) NULL,
    [FreightFlatBillingAmount]      DECIMAL (18, 6) NULL,
    [MaterialBuildMethod]           INT             NULL,
    [LaborBuildMethod]              INT             NULL,
    [ChargesBuildMethod]            INT             NULL,
    [FreightBuildMethod]            INT             NULL,
    [ExclusionsBuildMethod]         INT             NULL,
    [MaterialMarkupId]              BIGINT          NULL,
    [LaborMarkupId]                 BIGINT          NULL,
    [ChargesMarkupId]               BIGINT          NULL,
    [FreightMarkupId]               BIGINT          NULL,
    [ExclusionsMarkupId]            BIGINT          NULL,
    [FreightRevenue]                DECIMAL (18, 6) NULL,
    [LaborRevenue]                  DECIMAL (18, 6) NULL,
    [MaterialRevenue]               DECIMAL (18, 6) NULL,
    [ExclusionsRevenue]             DECIMAL (18, 6) NULL,
    [ChargesRevenue]                DECIMAL (18, 6) NULL,
    [OverHeadCostRevenuePercentage] DECIMAL (18, 6) NULL,
    [QuoteParentId]                 BIGINT          NULL,
    [IsVersionIncrease]             BIT             NULL,
    [QuoteMethod]                   BIT             NULL,
    [CommonFlatRate]                DECIMAL (18, 6) NULL,
    [EvalFees]                      DECIMAL (18, 6) NULL
);

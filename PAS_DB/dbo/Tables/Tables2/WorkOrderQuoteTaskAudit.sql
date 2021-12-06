﻿CREATE TABLE [dbo].[WorkOrderQuoteTaskAudit] (
    [WorkOrderQuoteTaskAuditId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteTaskId]          BIGINT          NOT NULL,
    [WOPartNoId]                    BIGINT          NOT NULL,
    [TaskId]                        BIGINT          NOT NULL,
    [LaborHours]                    INT             NULL,
    [LaborCost]                     DECIMAL (20, 2) NULL,
    [LaborBilling]                  DECIMAL (20, 2) NULL,
    [LaborRevenue]                  DECIMAL (20, 2) NULL,
    [LaborRevnuePercentage]         DECIMAL (20, 2) NULL,
    [LaborMargin]                   DECIMAL (20, 2) NULL,
    [MaterialCost]                  DECIMAL (20, 2) NULL,
    [MaterialBilling]               DECIMAL (20, 2) NULL,
    [MaterialRevenue]               DECIMAL (20, 2) NULL,
    [MaterialRevnuePercentage]      DECIMAL (20, 2) NULL,
    [MaterialMargin]                DECIMAL (20, 2) NULL,
    [ChargesCost]                   DECIMAL (20, 2) NULL,
    [ChargesBilling]                DECIMAL (20, 2) NULL,
    [ChargesRevenue]                DECIMAL (20, 2) NULL,
    [ChargesRevnuePercentage]       DECIMAL (20, 2) NULL,
    [ChargesMargin]                 DECIMAL (20, 2) NULL,
    [FreightCost]                   DECIMAL (20, 2) NULL,
    [FreightBilling]                DECIMAL (20, 2) NULL,
    [FreightRevenue]                DECIMAL (20, 2) NULL,
    [FreightRevnuePercentage]       DECIMAL (20, 2) NULL,
    [FreightMargin]                 DECIMAL (20, 2) NULL,
    [ExclusionsCost]                DECIMAL (20, 2) NULL,
    [ExclusionsBilling]             DECIMAL (20, 2) NULL,
    [ExclusionsRevenue]             DECIMAL (20, 2) NULL,
    [ExclusionsRevnuePercentage]    DECIMAL (20, 2) NULL,
    [ExclusionsMargin]              DECIMAL (20, 2) NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             NOT NULL,
    [IsDeleted]                     BIT             NOT NULL,
    [MaterialMarginPer]             DECIMAL (20, 2) NULL,
    [LaborMarginPer]                DECIMAL (20, 2) NULL,
    [ChargesMarginPer]              DECIMAL (20, 2) NULL,
    [ExclusionsMarginPer]           DECIMAL (20, 2) NULL,
    [FreightMarginPer]              DECIMAL (20, 2) NULL,
    [OverHeadCost]                  DECIMAL (20, 2) NULL,
    [AdjustmentHours]               INT             NULL,
    [AdjustedHours]                 INT             NULL,
    [WorkOrderLaborHeaderId]        BIGINT          NULL,
    [ChargesRevenuePercentage]      DECIMAL (20, 2) NULL,
    [ExclusionsRevenuePercentage]   DECIMAL (20, 2) NULL,
    [FreightRevenuePercentage]      DECIMAL (20, 2) NULL,
    [LaborRevenuePercentage]        DECIMAL (20, 2) NULL,
    [MaterialRevenuePercentage]     DECIMAL (20, 2) NULL,
    [OverHeadCostRevenuePercentage] DECIMAL (20, 2) NULL,
    CONSTRAINT [PK_WorkOrderQuoteTaskAudit] PRIMARY KEY CLUSTERED ([WorkOrderQuoteTaskAuditId] ASC)
);


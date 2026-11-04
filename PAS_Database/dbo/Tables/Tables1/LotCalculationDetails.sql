CREATE TABLE [dbo].[LotCalculationDetails] (
    [LotCalculationId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [LotId]                    BIGINT          NULL,
    [LotTransInOutId]          BIGINT          NULL,
    [Type]                     VARCHAR (MAX)   NOT NULL,
    [ReferenceId]              BIGINT          NULL,
    [ChildId]                  BIGINT          NULL,
    [OriginalCost]             DECIMAL (18, 6) NULL,
    [RepairCost]               DECIMAL (18, 6) NULL,
    [AdjustedLotCost]          DECIMAL (18, 6) NULL,
    [RepCost]                  DECIMAL (18, 6) NULL,
    [Qty]                      DECIMAL (18, 6) NULL,
    [TransferredInCost]        DECIMAL (18, 6) NULL,
    [TransferredOutCost]       DECIMAL (18, 6) NULL,
    [RemainingCost]            DECIMAL (18, 6) NULL,
    [OtherCost]                DECIMAL (18, 6) NULL,
    [TotalLotCost]             DECIMAL (18, 6) NULL,
    [Revenue]                  DECIMAL (18, 6) NULL,
    [CogsPartsCost]            DECIMAL (18, 6) NULL,
    [CommissionExpense]        DECIMAL (18, 6) NULL,
    [TotalExpense]             DECIMAL (18, 6) NULL,
    [MarginAmt]                DECIMAL (18, 6) NULL,
    [MarginPercent]            DECIMAL (18, 6) NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_LotCalculationDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_LotCalculationDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [FreightCost]              DECIMAL (18, 6) NULL,
    [InsuranceCost]            DECIMAL (18, 6) NULL,
    [HandlingCost]             DECIMAL (18, 6) NULL,
    [TeardownCost]             DECIMAL (18, 6) NULL,
    [SoldCost]                 DECIMAL (18, 6) NULL,
    [SalesUnitPrice]           DECIMAL (18, 6) NULL,
    [ExtSalesUnitPrice]        DECIMAL (18, 6) NULL,
    [Margin]                   DECIMAL (18, 6) NULL,
    [MarginAmount]             DECIMAL (18, 6) NULL,
    [Cogs]                     DECIMAL (18, 6) NULL,
    [PreCostStocklinePrice]    DECIMAL (18, 6) NULL,
    [ExtPreCostStocklinePrice] DECIMAL (18, 6) NULL,
    [IsFromPreCostStk]         BIT             NULL,
    [IsRevenue]                BIT             NULL,
    [IsMargin]                 BIT             NULL,
    [IsFixedAmount]            BIT             NULL,
    [PercentId]                BIGINT          NULL,
    [PerAmount]                DECIMAL (18, 6) NULL,
    [HowCalculate]              VARCHAR (50)    NULL,
    -- [PN-17881] mirror of LotConsignment's revenue/margin split + consignee fields, populated in
    -- USP_Lot_AddUpdateLotCalculationDetails at UPPER(@Type) = UPPER('Trans Out (SO)'). Kept as separate
    -- columns (not reusing the existing PercentId/PerAmount above, which already hold different combined
    -- values) - name mapping from LotConsignment: PercentId -> RevenuePercentId, PerAmount -> FixedAmount,
    -- ConsignorPercentId -> RevenueConsignorPercentId; MarginPercentId/MarginConsignorPercentId/
    -- ConsigneeTypeId/ConsigneeId keep the same names as LotConsignment.
    [RevenuePercentId]         BIGINT          NULL,
    [FixedAmount]              DECIMAL (18, 6) NULL,
    [RevenueConsignorPercentId] BIGINT         NULL,
    [MarginPercentId]          BIGINT          NULL,
    [MarginConsignorPercentId] BIGINT          NULL,
    [ConsigneeTypeId]          INT             NULL,
    [ConsigneeId]              BIGINT          NULL,
    -- PN-18257: SO invoice mapping, populated only for Type = 'Trans Out (SO)' (PASConstants.LOT_TransOut_SO)
    -- so a Trans Out (SO) row can be traced to the BillingInvoicing / BillingInvoicingItems it was posted from.
    [BillingInvoicingId]       BIGINT          NULL,
    [BillingInvoicingItemId]   BIGINT          NULL,
    CONSTRAINT [PK_LotCalculationDetails] PRIMARY KEY CLUSTERED ([LotCalculationId] ASC),
    CONSTRAINT [FK_LotCalculationDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);
GO
CREATE NONCLUSTERED INDEX [IX_LotCalculationDetails_LotTransInOutId]
    ON [dbo].[LotCalculationDetails]([LotTransInOutId] ASC)
    INCLUDE([Type], [ReferenceId], [ChildId], [Qty], [TransferredInCost], [TransferredOutCost], [SalesUnitPrice], [ExtSalesUnitPrice], [MarginAmount], [CommissionExpense], [CreatedDate]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);
-- Added 2026-08-11: this was the primary fix for the USP_Lot_GetAllLotViewsByLotId_Filter timeout -
-- supports "INNER JOIN ... ltCal ON ltin.LotTransInOutId = ltCal.LotTransInOutId" used in every
-- @Type branch (see UOM_USP_Lot_GetAllLotViewsByLotId_Filter_Deploy.sql for the full review).


GO
-- [PN-18450] 29-Oct-2026 - Performance: dbo.USP_Lot_GetLotList (30+ sec) one pass per lot for repair / trans in / trans out / revenue / margin / sold cost
CREATE NONCLUSTERED INDEX [IX_LotCalculationDetails_LotId_Perf]
    ON [dbo].[LotCalculationDetails]([LotId] ASC)
    INCLUDE([Type], [IsFromPreCostStk], [RepairCost], [TransferredInCost], [TransferredOutCost], [Qty], [ReferenceId], [ChildId], [ExtSalesUnitPrice], [MarginAmount]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

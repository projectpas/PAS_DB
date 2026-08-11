CREATE TABLE [dbo].[LotCalculationDetails] (
    [LotCalculationId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [LotId]                    BIGINT          NULL,
    [LotTransInOutId]          BIGINT          NULL,
    [Type]                     VARCHAR (MAX)   NOT NULL,
    [ReferenceId]              BIGINT          NULL,
    [ChildId]                  BIGINT          NULL,
    [OriginalCost]             DECIMAL (18, 2) NULL,
    [RepairCost]               DECIMAL (18, 2) NULL,
    [AdjustedLotCost]          DECIMAL (18, 2) NULL,
    [RepCost]                  DECIMAL (18, 2) NULL,
    [Qty]                      INT             NULL,
    [TransferredInCost]        DECIMAL (18, 2) NULL,
    [TransferredOutCost]       DECIMAL (18, 2) NULL,
    [RemainingCost]            DECIMAL (18, 2) NULL,
    [OtherCost]                DECIMAL (18, 2) NULL,
    [TotalLotCost]             DECIMAL (18, 2) NULL,
    [Revenue]                  DECIMAL (18, 2) NULL,
    [CogsPartsCost]            DECIMAL (18, 2) NULL,
    [CommissionExpense]        DECIMAL (18, 2) NULL,
    [TotalExpense]             DECIMAL (18, 2) NULL,
    [MarginAmt]                DECIMAL (18, 2) NULL,
    [MarginPercent]            DECIMAL (18, 2) NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_LotCalculationDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_LotCalculationDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [FreightCost]              DECIMAL (18, 2) NULL,
    [InsuranceCost]            DECIMAL (18, 2) NULL,
    [HandlingCost]             DECIMAL (18, 2) NULL,
    [TeardownCost]             DECIMAL (18, 2) NULL,
    [SoldCost]                 DECIMAL (18, 2) NULL,
    [SalesUnitPrice]           DECIMAL (18, 2) NULL,
    [ExtSalesUnitPrice]        DECIMAL (18, 2) NULL,
    [Margin]                   DECIMAL (18, 2) NULL,
    [MarginAmount]             DECIMAL (18, 2) NULL,
    [Cogs]                     DECIMAL (18, 2) NULL,
    [PreCostStocklinePrice]    DECIMAL (18, 2) NULL,
    [ExtPreCostStocklinePrice] DECIMAL (18, 2) NULL,
    [IsFromPreCostStk]         BIT             NULL,
    [IsRevenue]                BIT             NULL,
    [IsMargin]                 BIT             NULL,
    [IsFixedAmount]            BIT             NULL,
    [PercentId]                BIGINT          NULL,
    [PerAmount]                DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_LotCalculationDetails] PRIMARY KEY CLUSTERED ([LotCalculationId] ASC),
    CONSTRAINT [FK_LotCalculationDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
-- Added to fix USP_Lot_GetAllLotViewsByLotId_Filter timeouts on high-volume lots: every branch of that
-- SP inner-joins this table on LotTransInOutId with no supporting index, forcing a full clustered-index
-- scan of the whole table (across ALL lots/companies) on every call. This makes that join a seek and
-- covers the columns the SP actually selects/filters on (Type, ReferenceId, ChildId - used as extra join
-- predicates for PO/RO branches) so it avoids key lookups back to the wide clustered row.
CREATE NONCLUSTERED INDEX [IX_LotCalculationDetails_LotTransInOutId]
    ON [dbo].[LotCalculationDetails]([LotTransInOutId] ASC)
    INCLUDE([Type], [ReferenceId], [ChildId], [Qty], [TransferredInCost], [TransferredOutCost],
            [SalesUnitPrice], [ExtSalesUnitPrice], [MarginAmount], [CommissionExpense], [CreatedDate]);


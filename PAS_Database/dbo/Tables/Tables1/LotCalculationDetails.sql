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


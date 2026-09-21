CREATE TABLE [dbo].[LeaseBillingInvoicingItemDetails] (
    [LeaseBillingInvoicingItemDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [BillingInvoicingItemId]            BIGINT          NOT NULL,
    [LeaseStocklineId]                  BIGINT          NOT NULL,
    [BillingMethod]                     VARCHAR (50)    NULL,
    [BillingFrequency]                  VARCHAR (100)   NULL,
    [TimeRecorded]                      DECIMAL (18, 6) NULL,
    [TimeLimit]                         DECIMAL (18, 6) NULL,
    [TimeOver]                          DECIMAL (18, 6) NULL,
    [TimeOverageRate]                   DECIMAL (18, 6) NULL,
    [TimeBillingAmount]                 DECIMAL (18, 6) NULL,
    [CycleRecorded]                     DECIMAL (18, 6) NULL,
    [CycleLimit]                        DECIMAL (18, 6) NULL,
    [CycleOver]                         DECIMAL (18, 6) NULL,
    [CycleOverageRate]                  DECIMAL (18, 6) NULL,
    [CycleBillingAmount]                DECIMAL (18, 6) NULL,
    [TotalBillingAmount]                DECIMAL (18, 6) NULL,
    [MasterCompanyId]                   INT             NOT NULL,
    [CreatedBy]                         VARCHAR (256)   NOT NULL,
    [UpdatedBy]                         VARCHAR (256)   NOT NULL,
    [CreatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_LeaseBillingInvoicingItemDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)   CONSTRAINT [DF_LeaseBillingInvoicingItemDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                          BIT             CONSTRAINT [DF_LeaseBillingInvoicingItemDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                         BIT             CONSTRAINT [DF_LeaseBillingInvoicingItemDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseBillingInvoicingItemDetails] PRIMARY KEY CLUSTERED ([LeaseBillingInvoicingItemDetailId] ASC),
    CONSTRAINT [FK_LeaseBillingInvoicingItemDetails_BillingInvoicingItems] FOREIGN KEY ([BillingInvoicingItemId]) REFERENCES [dbo].[BillingInvoicingItems] ([BillingInvoicingItemId]),
    CONSTRAINT [FK_LeaseBillingInvoicingItemDetails_LeaseStockline] FOREIGN KEY ([LeaseStocklineId]) REFERENCES [dbo].[LeaseStockline] ([LeaseStocklineId])
);


GO
CREATE NONCLUSTERED INDEX [IX_LeaseBillingInvoicingItemDetails_LeaseStocklineId]
    ON [dbo].[LeaseBillingInvoicingItemDetails]([LeaseStocklineId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_LeaseBillingInvoicingItemDetails_BillingInvoicingItemId]
    ON [dbo].[LeaseBillingInvoicingItemDetails]([BillingInvoicingItemId] ASC);


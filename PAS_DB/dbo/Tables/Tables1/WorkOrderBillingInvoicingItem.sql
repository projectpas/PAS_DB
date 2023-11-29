CREATE TABLE [dbo].[WorkOrderBillingInvoicingItem] (
    [WOBillingInvoicingItemId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [BillingInvoicingId]       BIGINT          NOT NULL,
    [NoofPieces]               INT             NOT NULL,
    [WorkOrderPartId]          BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_WorkOrderBillingInvoicingItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_WorkOrderBillingInvoicingItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [WorkOrderBillingInvoicingItem_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [WorkOrderBillingInvoicingItem_DC_Deleted] DEFAULT ((0)) NOT NULL,
    [UnitPrice]                DECIMAL (20, 2) NULL,
    [SubTotal]                 DECIMAL (20, 2) NULL,
    [TaxRate]                  DECIMAL (20, 2) NULL,
    [SalesTax]                 DECIMAL (20, 2) NULL,
    [OtherTax]                 DECIMAL (20, 2) NULL,
    [MiscCharges]              DECIMAL (20, 2) NULL,
    [Freight]                  DECIMAL (20, 2) NULL,
    [PDFPath]                  NVARCHAR (MAX)  NULL,
    [VersionNo]                VARCHAR (20)    NULL,
    [IsVersionIncrease]        BIT             NULL,
    [ConditionId]              BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderBillingInvoicingItem] PRIMARY KEY CLUSTERED ([WOBillingInvoicingItemId] ASC),
    FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicingItem_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicingItem_WorkOrderBillingInvoicing] FOREIGN KEY ([BillingInvoicingId]) REFERENCES [dbo].[WorkOrderBillingInvoicing] ([BillingInvoicingId])
);




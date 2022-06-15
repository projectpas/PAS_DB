CREATE TABLE [dbo].[CustomerRMADeatils] (
    [RMADeatilsId]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [RMAHeaderId]            BIGINT          NOT NULL,
    [ItemMasterId]           BIGINT          NOT NULL,
    [PartNumber]             VARCHAR (100)   NULL,
    [PartDescription]        VARCHAR (MAX)   NULL,
    [AltPartNumber]          VARCHAR (100)   NULL,
    [CustPartNumber]         VARCHAR (100)   NULL,
    [SerialNumber]           VARCHAR (100)   NULL,
    [StocklineId]            BIGINT          NOT NULL,
    [StocklineNumber]        VARCHAR (100)   NOT NULL,
    [ControlNumber]          VARCHAR (100)   NULL,
    [ControlId]              VARCHAR (100)   NULL,
    [ReferenceId]            BIGINT          NOT NULL,
    [ReferenceNo]            VARCHAR (100)   NULL,
    [Qty]                    INT             NOT NULL,
    [UnitPrice]              DECIMAL (18, 2) NULL,
    [Amount]                 DECIMAL (18, 2) NULL,
    [RMAReasonId]            BIGINT          NOT NULL,
    [RMAReason]              VARCHAR (500)   NULL,
    [Notes]                  NVARCHAR (MAX)  NULL,
    [isWorkOrder]            BIT             CONSTRAINT [CustomerRMADeatils_DC_isWorkOrder] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_CustomerRMADeatils_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_CustomerRMADeatils_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [CustomerRMADeatils_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [CustomerRMADeatils_DC_Delete] DEFAULT ((0)) NOT NULL,
    [InvoiceId]              BIGINT          NOT NULL,
    [BillingInvoicingItemId] BIGINT          NOT NULL,
    [IsCreateStockline]      BIT             NULL,
    [CustomerReference]      VARCHAR (100)   NULL,
    [InvoiceQty]             INT             CONSTRAINT [InvoiceQty] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_CustomerRMADeatils] PRIMARY KEY CLUSTERED ([RMADeatilsId] ASC),
    CONSTRAINT [FK_CustomerRMADeatils_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_CustomerRMADeatils_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CustomerRMADeatils_RMAReasonId] FOREIGN KEY ([RMAReasonId]) REFERENCES [dbo].[RMAReason] ([RMAReasonId]),
    CONSTRAINT [FK_CustomerRMADeatils_StocklineId] FOREIGN KEY ([StocklineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);






GO




CREATE TRIGGER [dbo].[Trg_CustomerRMADeatilsAudit]

   ON  [dbo].[CustomerRMADeatils]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerRMADeatilsAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END
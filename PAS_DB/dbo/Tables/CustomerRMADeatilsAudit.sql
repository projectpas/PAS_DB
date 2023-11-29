CREATE TABLE [dbo].[CustomerRMADeatilsAudit] (
    [RMADeatilsAuditId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [RMADeatilsId]           BIGINT          NOT NULL,
    [RMAHeaderId]            BIGINT          NOT NULL,
    [ItemMasterId]           BIGINT          NOT NULL,
    [PartNumber]             VARCHAR (100)   NULL,
    [PartDescription]        VARCHAR (MAX)   NULL,
    [AltPartNumber]          VARCHAR (100)   NULL,
    [CustPartNumber]         VARCHAR (100)   NULL,
    [SerialNumber]           VARCHAR (100)   NULL,
    [StocklineId]            BIGINT          NULL,
    [StocklineNumber]        VARCHAR (100)   NULL,
    [ControlNumber]          VARCHAR (100)   NULL,
    [ControlId]              VARCHAR (100)   NULL,
    [ReferenceId]            BIGINT          NULL,
    [ReferenceNo]            VARCHAR (100)   NULL,
    [Qty]                    INT             NULL,
    [UnitPrice]              DECIMAL (18, 2) NULL,
    [Amount]                 DECIMAL (18, 2) NULL,
    [RMAReasonId]            INT             NULL,
    [RMAReason]              VARCHAR (500)   NULL,
    [Notes]                  NVARCHAR (MAX)  NULL,
    [isWorkOrder]            BIT             NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   NOT NULL,
    [IsActive]               BIT             NOT NULL,
    [IsDeleted]              BIT             NOT NULL,
    [InvoiceId]              BIGINT          NULL,
    [BillingInvoicingItemId] BIGINT          NULL,
    [IsCreateStockline]      BIT             NULL,
    [CustomerReference]      VARCHAR (100)   NULL,
    [InvoiceQty]             INT             NULL,
    [ReturnDate]             DATETIME2 (7)   NULL,
    [WorkOrderNum]           VARCHAR (50)    NULL,
    [ReceiverNum]            VARCHAR (50)    NULL,
    CONSTRAINT [PK_CustomerRMADeatilsAudit] PRIMARY KEY CLUSTERED ([RMADeatilsAuditId] ASC)
);








CREATE TABLE [dbo].[LeaseShippingItem] (
    [LeaseShippingItemId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseShippingId]     BIGINT          NOT NULL,
    [LeaseHeaderId]       BIGINT          NOT NULL,
    [LeaseStocklineId]    BIGINT          NOT NULL,
    [StocklineId]         BIGINT          NULL,
    [QtyShipped]          DECIMAL (18, 6) NULL,
    [LeasePickTicketId]   BIGINT          NOT NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   CONSTRAINT [DF_LeaseShippingItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)   CONSTRAINT [DF_LeaseShippingItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT             CONSTRAINT [DF_LeaseShippingItem_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT             CONSTRAINT [DF_LeaseShippingItem_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PDFPath]             NVARCHAR (MAX)  NULL,
    [FedexPdfPath]        VARCHAR (MAX)   NULL,
    [UPSPdfPath]          VARCHAR (MAX)   NULL,
    CONSTRAINT [PK_LeaseShippingItem] PRIMARY KEY CLUSTERED ([LeaseShippingItemId] ASC)
);


GO

CREATE TRIGGER [dbo].[Trg_LeaseShippingItemAudit]

   ON  [dbo].[LeaseShippingItem]

   AFTER INSERT,UPDATE

AS 
BEGIN	   

	INSERT INTO [dbo].[LeaseShippingItemAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;

END
CREATE TABLE [dbo].[SalesOrderShippingItem] (
    [SalesOrderShippingItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SalesOrderShippingId]     BIGINT         NOT NULL,
    [SalesOrderPartId]         BIGINT         NOT NULL,
    [QtyShipped]               INT            NULL,
    [SOPickTicketId]           BIGINT         NOT NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DF_SalesOrderShippingItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  CONSTRAINT [DF_SalesOrderShippingItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT            CONSTRAINT [DF_SOSI_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT            CONSTRAINT [DF_SOSI_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PDFPath]                  NVARCHAR (MAX) NULL,
    [FedexPdfPath]             VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_SalesOrderShippingItem] PRIMARY KEY CLUSTERED ([SalesOrderShippingItemId] ASC),
    CONSTRAINT [FK_SalesOrderShippingItem_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderShippingItem_SOPickTicket] FOREIGN KEY ([SOPickTicketId]) REFERENCES [dbo].[SOPickTicket] ([SOPickTicketId])
);


GO


CREATE TRIGGER [dbo].[Trg_SalesOrderShippingItemAudit]

   ON  [dbo].[SalesOrderShippingItem]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderShippingItemAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
CREATE TABLE [dbo].[ExchangeSalesOrderShippingItem] (
    [ExchangeSalesOrderShippingItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderShippingId]     BIGINT         NOT NULL,
    [ExchangeSalesOrderPartId]         BIGINT         NOT NULL,
    [QtyShipped]                       INT            NULL,
    [SOPickTicketId]                   BIGINT         NOT NULL,
    [MasterCompanyId]                  INT            NOT NULL,
    [CreatedBy]                        VARCHAR (256)  NOT NULL,
    [UpdatedBy]                        VARCHAR (256)  NOT NULL,
    [CreatedDate]                      DATETIME2 (7)  CONSTRAINT [DF_ExchangeSalesOrderShippingItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7)  CONSTRAINT [DF_ExchangeSalesOrderShippingItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                         BIT            CONSTRAINT [DF_ExchangeSalesOrderShippingItem_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT            CONSTRAINT [DF_ExchangeSalesOrderShippingItem_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PDFPath]                          NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_ExchangeSalesOrderShippingItem] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderShippingItemId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderShippingItem_ExchangeSalesOrderPart] FOREIGN KEY ([ExchangeSalesOrderPartId]) REFERENCES [dbo].[ExchangeSalesOrderPart] ([ExchangeSalesOrderPartId]),
    CONSTRAINT [FK_ExchangeSalesOrderShippingItem_ExchangeSalesOrderShipping] FOREIGN KEY ([ExchangeSalesOrderShippingId]) REFERENCES [dbo].[ExchangeSalesOrderShipping] ([ExchangeSalesOrderShippingId]),
    CONSTRAINT [FK_ExchangeSalesOrderShippingItem_ExchangeSOPickTicket] FOREIGN KEY ([SOPickTicketId]) REFERENCES [dbo].[ExchangeSOPickTicket] ([SOPickTicketId]),
    CONSTRAINT [FK_ExchangeSalesOrderShippingItem_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderShippingItemAudit]

   ON  [dbo].[ExchangeSalesOrderShippingItem]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderShippingItemAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
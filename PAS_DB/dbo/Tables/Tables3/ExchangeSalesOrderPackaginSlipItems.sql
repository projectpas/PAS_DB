CREATE TABLE [dbo].[ExchangeSalesOrderPackaginSlipItems] (
    [PackagingSlipItemId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [PackagingSlipId]          BIGINT         NOT NULL,
    [SOPickTicketId]           BIGINT         NOT NULL,
    [ExchangeSalesOrderPartId] BIGINT         NOT NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  NOT NULL,
    [IsActive]                 BIT            NOT NULL,
    [IsDeleted]                BIT            NOT NULL,
    [PDFPath]                  NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_ExchangeSalesOrderPackaginSlipItems] PRIMARY KEY CLUSTERED ([PackagingSlipItemId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderPackaginSlipItems_ExchangeSalesOrderPackaginSlipHeader] FOREIGN KEY ([PackagingSlipId]) REFERENCES [dbo].[ExchangeSalesOrderPackaginSlipHeader] ([PackagingSlipId]),
    CONSTRAINT [FK_ExchangeSalesOrderPackaginSlipItems_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderPackaginSlipItemsAudit]

   ON  [dbo].[ExchangeSalesOrderPackaginSlipItems]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeSalesOrderPackaginSlipItemsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
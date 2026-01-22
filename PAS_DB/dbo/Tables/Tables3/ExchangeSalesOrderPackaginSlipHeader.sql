CREATE TABLE [dbo].[ExchangeSalesOrderPackaginSlipHeader] (
    [PackagingSlipId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [PackagingSlipNo]      VARCHAR (50)  NOT NULL,
    [ExchangeSalesOrderId] BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    CONSTRAINT [PK_ExchangeSalesOrderPackaginSlipHeader] PRIMARY KEY CLUSTERED ([PackagingSlipId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderPackaginSlipHeader_ExchangeSalesOrder] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId]),
    CONSTRAINT [FK_ExchangeSalesOrderPackaginSlipHeader_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderPackaginSlipHeaderAudit]

   ON  [dbo].[ExchangeSalesOrderPackaginSlipHeader]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeSalesOrderPackaginSlipHeaderAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
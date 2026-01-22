CREATE TABLE [dbo].[SOPartsMapping] (
    [SOPartsMappingId]  BIGINT IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId] BIGINT NULL,
    [SalesOrderId]      BIGINT NOT NULL,
    [SalesOrderPartId]  BIGINT NOT NULL,
    [ItemMasterId]      BIGINT NOT NULL,
    [StockLineId]       BIGINT NULL,
    [Quantity]          INT    NOT NULL,
    CONSTRAINT [PK_SOPartsMapping] PRIMARY KEY CLUSTERED ([SOPartsMappingId] ASC),
    CONSTRAINT [FK_SOPartsMapping_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SOPartsMapping_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SOPartsMapping_SalesOrderPart] FOREIGN KEY ([SalesOrderPartId]) REFERENCES [dbo].[SalesOrderPart] ([SalesOrderPartId])
);


GO


CREATE TRIGGER [dbo].[Trg_AuditSOPartsMapping]

   ON  [dbo].[SOPartsMapping]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SOPartsMappingAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
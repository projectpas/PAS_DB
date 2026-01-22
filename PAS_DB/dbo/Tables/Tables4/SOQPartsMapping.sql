CREATE TABLE [dbo].[SOQPartsMapping] (
    [SOQPartsMappingId]     BIGINT IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]     BIGINT NOT NULL,
    [SalesOrderQuotePartId] BIGINT NOT NULL,
    [ItemMasterId]          BIGINT NOT NULL,
    [StockLineId]           BIGINT NULL,
    [Quantity]              INT    NOT NULL,
    CONSTRAINT [PK_SOQPartsMapping] PRIMARY KEY CLUSTERED ([SOQPartsMappingId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_AuditSOQPartsMapping]

   ON  [dbo].[SOQPartsMapping]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SOQPartsMappingAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
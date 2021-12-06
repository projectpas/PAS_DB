CREATE TABLE [dbo].[ItemNonStockClassification] (
    [ItemNonStockClassificationId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemNonStockClassificationCode] VARCHAR (30)  NOT NULL,
    [Description]                    VARCHAR (100) NOT NULL,
    [ItemType]                       VARCHAR (500) NULL,
    [Memo]                           VARCHAR (MAX) NULL,
    [MastercompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NULL,
    [UpdatedBy]                      VARCHAR (256) NULL,
    [CreatedDate]                    DATETIME2 (7) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) NOT NULL,
    [IsActive]                       BIT           NULL,
    [IsDeleted]                      BIT           NULL,
    CONSTRAINT [PK_ItemNonStockClassification] PRIMARY KEY CLUSTERED ([ItemNonStockClassificationId] ASC),
    CONSTRAINT [UQ_ItemNonStockClassification_codes] UNIQUE NONCLUSTERED ([ItemNonStockClassificationCode] ASC, [ItemType] ASC, [MastercompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ItemNonStockClassificationAudit]

   ON  [dbo].[ItemNonStockClassification]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ItemNonStockClassificationAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
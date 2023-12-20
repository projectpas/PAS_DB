CREATE TABLE [dbo].[SpeedQuoteExclusionPart] (
    [ExclusionPartId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [SpeedQuoteId]      BIGINT          NULL,
    [SpeedQuotePartId]  BIGINT          NULL,
    [ItemMasterId]      BIGINT          NULL,
    [PN]                VARCHAR (100)   NULL,
    [Description]       NVARCHAR (MAX)  NULL,
    [ExPartNumber]      VARCHAR (100)   NULL,
    [ExPartDescription] NVARCHAR (MAX)  NULL,
    [ExQuantity]        INT             NULL,
    [ExItemMasterId]    BIGINT          NULL,
    [ExStockType]       VARCHAR (50)    NULL,
    [ExUnitPrice]       NUMERIC (18, 2) NULL,
    [ExExtPrice]        NUMERIC (18, 2) NULL,
    [ExOccurance]       INT             NULL,
    [ExCurr]            VARCHAR (50)    NULL,
    [ExNotes]           NVARCHAR (MAX)  NULL,
    [MasterCompanyId]   INT             NOT NULL,
    [CreatedBy]         VARCHAR (256)   NOT NULL,
    [UpdatedBy]         VARCHAR (256)   NOT NULL,
    [CreatedDate]       DATETIME2 (7)   CONSTRAINT [DF_SpeedQuoteExclusionPart_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)   CONSTRAINT [DF_SpeedQuoteExclusionPart_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT             CONSTRAINT [DF_SpeedQuoteExclusionPart_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT             CONSTRAINT [DF_SpeedQuoteExclusionPart_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ItemNo]            INT             CONSTRAINT [DF__SpeedQuot__ItemN__00B39F61] DEFAULT ((0)) NOT NULL,
    [ConditionId]       INT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SpeedQuoteExclusionPart] PRIMARY KEY CLUSTERED ([ExclusionPartId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_SpeedQuoteExclusionPartAudit]

   ON  [dbo].[SpeedQuoteExclusionPart]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SpeedQuoteExclusionPartAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
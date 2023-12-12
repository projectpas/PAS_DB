CREATE TABLE [dbo].[ARSettings] (
    [ARSettingId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [TradeARAccount]  BIGINT        NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_ARSettings] PRIMARY KEY CLUSTERED ([ARSettingId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ARSettingsAudit]

   ON  [dbo].[ARSettings]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ARSettingsAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
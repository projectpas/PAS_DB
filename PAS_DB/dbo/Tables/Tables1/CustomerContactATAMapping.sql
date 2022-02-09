CREATE TABLE [dbo].[CustomerContactATAMapping] (
    [CustomerContactATAMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                  BIGINT        NOT NULL,
    [CustomerContactId]           BIGINT        NOT NULL,
    [ATAChapterId]                BIGINT        NULL,
    [ATAChapterCode]              VARCHAR (256) NULL,
    [ATAChapterName]              VARCHAR (250) NULL,
    [ATASubChapterId]             BIGINT        NULL,
    [ATASubChapterDescription]    VARCHAR (256) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_CustomerContactATAMapping_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_CustomerContactATAMapping_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [D_CCAM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [CustomerContactATAMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ATASubChapterCode]           VARCHAR (250) NULL,
    [Level1]                      VARCHAR (50)  NULL,
    [Level2]                      VARCHAR (50)  NULL,
    [Level3]                      VARCHAR (50)  NULL,
    CONSTRAINT [PK_CCATAMapping] PRIMARY KEY CLUSTERED ([CustomerContactATAMappingId] ASC),
    CONSTRAINT [FK_CustomerContactATAMapping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerContactATAMapping_CustomerContact] FOREIGN KEY ([CustomerContactId]) REFERENCES [dbo].[CustomerContact] ([CustomerContactId]),
    CONSTRAINT [FK_CustomerContactATAMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO


CREATE TRIGGER [dbo].[Trg_CustomerContactATAMappingAudit]

   ON  [dbo].[CustomerContactATAMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[CustomerContactATAMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_CustomerContactATAMappingDelete]

   ON  [dbo].[CustomerContactATAMapping]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[CustomerContactATAMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
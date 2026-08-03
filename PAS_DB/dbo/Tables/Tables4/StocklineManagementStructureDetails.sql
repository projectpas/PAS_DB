CREATE TABLE [dbo].[StocklineManagementStructureDetails] (
    [MSDetailsId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleID]        INT           NOT NULL,
    [ReferenceID]     BIGINT        NOT NULL,
    [EntityMSID]      BIGINT        NOT NULL,
    [Level1Id]        BIGINT        NULL,
    [Level1Name]      VARCHAR (500) NULL,
    [Level2Id]        BIGINT        NULL,
    [Level2Name]      VARCHAR (500) NULL,
    [Level3Id]        BIGINT        NULL,
    [Level3Name]      VARCHAR (500) NULL,
    [Level4Id]        BIGINT        NULL,
    [Level4Name]      VARCHAR (500) NULL,
    [Level5Id]        BIGINT        NULL,
    [Level5Name]      VARCHAR (500) NULL,
    [Level6Id]        BIGINT        NULL,
    [Level6Name]      VARCHAR (500) NULL,
    [Level7Id]        BIGINT        NULL,
    [Level7Name]      VARCHAR (500) NULL,
    [Level8Id]        BIGINT        NULL,
    [Level8Name]      VARCHAR (500) NULL,
    [Level9Id]        BIGINT        NULL,
    [Level9Name]      VARCHAR (500) NULL,
    [Level10Id]       BIGINT        NULL,
    [Level10Name]     VARCHAR (500) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_StocklineManagmentStructureDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_StocklineManagmentStructureDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_StocklineManagmentStructureDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_StocklineManagmentStructureDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LastMSLevel]     VARCHAR (200) NULL,
    [AllMSlevels]     VARCHAR (MAX) NULL,
    CONSTRAINT [PK_StocklineManagmentStructureDetails] PRIMARY KEY CLUSTERED ([MSDetailsId] ASC)
);




GO

CREATE TRIGGER [dbo].[Trg_StocklineManagementStructureDetailsAudit]

   ON  [dbo].[StocklineManagementStructureDetails]

   AFTER INSERT,DELETE,UPDATE
AS

BEGIN

INSERT INTO StocklineManagementStructureDetailsAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
GO
CREATE NONCLUSTERED INDEX [IX_SMSD_Report]
    ON [dbo].[StocklineManagementStructureDetails]([ModuleID] ASC, [ReferenceID] ASC)
    INCLUDE([EntityMSID], [Level1Id], [Level2Id], [Level3Id], [Level4Id], [Level5Id], [Level6Id], [Level7Id], [Level8Id], [Level9Id], [Level10Id], [Level1Name], [Level2Name], [Level3Name], [Level4Name], [Level5Name], [Level6Name], [Level7Name], [Level8Name], [Level9Name], [Level10Name]);


GO
CREATE NONCLUSTERED INDEX [IX_SLMSD_Module_Ref]
    ON [dbo].[StocklineManagementStructureDetails]([ModuleID] ASC, [ReferenceID] ASC)
    INCLUDE([EntityMSID], [Level1Id], [Level2Id], [Level3Id], [Level4Id], [Level5Id], [Level6Id], [Level7Id], [Level8Id], [Level9Id], [Level10Id], [Level1Name], [Level2Name], [Level3Name], [Level4Name], [Level5Name], [Level6Name], [Level7Name], [Level8Name], [Level9Name], [Level10Name]);


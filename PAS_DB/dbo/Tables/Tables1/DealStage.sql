CREATE TABLE [dbo].[DealStage] (
    [DealStageId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [DealStageName]   VARCHAR (256) NOT NULL,
    [Sequence]        INT           NOT NULL,
    [DealStatus]      VARCHAR (50)  NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DealStage_DC_CDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DealStage_DC_UDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DealStage_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DealStage_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DealStage] PRIMARY KEY CLUSTERED ([DealStageId] ASC),
    CONSTRAINT [FK_DealStage_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_DealStage] UNIQUE NONCLUSTERED ([DealStageName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_DealStageAudit]

   ON  [dbo].[DealStage]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO DealStageAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
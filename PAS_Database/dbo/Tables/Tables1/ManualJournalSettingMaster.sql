CREATE TABLE [dbo].[ManualJournalSettingMaster] (
    [ManualJournalSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [IsEnforceApproval]      BIT           CONSTRAINT [DF_ManualJournalSettingMaster_IsEnforceApproval] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_ManualJournalSettingMaster_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_ManualJournalSettingMaster_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF_ManualJournalSettingMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_ManualJournalSettingMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Effectivedate]          DATETIME2 (7) NULL,
    CONSTRAINT [PK_ManualJournalSettingMaster] PRIMARY KEY CLUSTERED ([ManualJournalSettingId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_ManualJournalSettingMasterAudit]
   ON  [dbo].[ManualJournalSettingMaster]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO ManualJournalSettingMasterAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
CREATE TABLE [dbo].[RepairOrderSettingMaster] (
    [RepairOrderSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [IsResale]             BIT           CONSTRAINT [DF_RepairOrderSettingMaster_IsResale] DEFAULT ((0)) NOT NULL,
    [IsDeferredReceiver]   BIT           CONSTRAINT [DF_RepairOrderSettingMaster_IsDeferredReceiver] DEFAULT ((0)) NOT NULL,
    [IsEnforceApproval]    BIT           CONSTRAINT [DF_RepairOrderSettingMaster_IsEnforceApproval] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_RepairOrderSettingMaster_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_RepairOrderSettingMaster_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_RepairOrderSettingMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_RepairOrderSettingMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Effectivedate]        DATETIME2 (7) NULL,
    [PriorityId]           BIGINT        NULL,
    [Priority]             VARCHAR (100) NULL,
    [IsRequestor]          BIT           NULL,
    CONSTRAINT [PK_RepairOrderSettingMaster] PRIMARY KEY CLUSTERED ([RepairOrderSettingId] ASC),
    CONSTRAINT [FK_RepairOrderSettingMaster_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);






GO




CREATE TRIGGER [dbo].[Trg_RepairOrderSettingMasterAudit]

   ON  [dbo].[RepairOrderSettingMaster]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO RepairOrderSettingMasterAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
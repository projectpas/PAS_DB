CREATE TABLE [dbo].[CycleCountSettingMaster] (
    [CycleCountSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [IsEnforceApproval]   BIT           CONSTRAINT [DF_CycleCountSettingMaster_IsEnforceApproval] DEFAULT ((0)) NOT NULL,
    [Effectivedate]       DATETIME2 (7) NULL,
    [StatusId]            BIGINT        NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_CycleCountSettingMaster_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_CycleCountSettingMaster_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_CycleCountSettingMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_CycleCountSettingMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CycleCountSettingMaster] PRIMARY KEY CLUSTERED ([CycleCountSettingId] ASC),
    CONSTRAINT [FK_CycleCountSettingMaster_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
CREATE   TRIGGER [dbo].[Trg_CycleCountSettingMasterAudit]

   ON  [dbo].[CycleCountSettingMaster]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CycleCountSettingMasterAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END
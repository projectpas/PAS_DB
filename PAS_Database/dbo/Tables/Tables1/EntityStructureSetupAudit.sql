CREATE TABLE [dbo].[EntityStructureSetupAudit] (
    [AuditEntityStructureId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EntityStructureId]      BIGINT        NOT NULL,
    [Level1Id]               INT           NULL,
    [Level2Id]               INT           NULL,
    [Level3Id]               INT           NULL,
    [Level4Id]               INT           NULL,
    [Level5Id]               INT           NULL,
    [Level6Id]               INT           NULL,
    [Level7Id]               INT           NULL,
    [Level8Id]               INT           NULL,
    [Level9Id]               INT           NULL,
    [Level10Id]              INT           NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_EntityStructureSetupAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_EntityStructureSetupAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF_EntityStructureSetupAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_EntityStructureSetupAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [OrganizationTagTypeId]  BIGINT        NULL,
    CONSTRAINT [PK_EntityStructureSetupAudit] PRIMARY KEY CLUSTERED ([AuditEntityStructureId] ASC)
);


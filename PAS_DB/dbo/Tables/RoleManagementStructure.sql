CREATE TABLE [dbo].[RoleManagementStructure] (
    [RoleManagementId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [RoleId]            BIGINT        NOT NULL,
    [EntityStructureId] BIGINT        NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [RoleManagementStructure_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [RoleManagementStructure_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [DF__RoleManagementStructure_IsAct__2630A1B7] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [DF__RoleManagementStructure__IsDel__2724C5F0] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__RoleManagementStructure__2C12D4026186959E] PRIMARY KEY CLUSTERED ([RoleManagementId] ASC),
    CONSTRAINT [FK_RoleManagementStructure_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_RoleManagementStructure] UNIQUE NONCLUSTERED ([RoleId] ASC, [EntityStructureId] ASC)
);


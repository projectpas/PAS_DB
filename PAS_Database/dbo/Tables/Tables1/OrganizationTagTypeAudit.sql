CREATE TABLE [dbo].[OrganizationTagTypeAudit] (
    [AuditOrganizationTagTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [OrganizationTagTypeId]      BIGINT         NULL,
    [Name]                       VARCHAR (100)  NOT NULL,
    [Memo]                       NVARCHAR (MAX) NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  CONSTRAINT [DF_OrganizationTagTypeAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  CONSTRAINT [DF_OrganizationTagTypeAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT            CONSTRAINT [DF_OrganizationTagTypeAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT            CONSTRAINT [DF_OrganizationTagTypeAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_OrganizationTagTypeAudit] PRIMARY KEY CLUSTERED ([AuditOrganizationTagTypeId] ASC)
);


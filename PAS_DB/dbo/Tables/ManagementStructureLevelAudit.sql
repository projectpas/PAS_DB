CREATE TABLE [dbo].[ManagementStructureLevelAudit] (
    [ManagmentStructureLevelAuditID] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ID]                             BIGINT         NOT NULL,
    [Code]                           VARCHAR (20)   NULL,
    [Description]                    NVARCHAR (MAX) NULL,
    [TypeID]                         INT            NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  CONSTRAINT [DF_ManagmentStructureLevelAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  CONSTRAINT [DF_ManagmentStructureLevelAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT            CONSTRAINT [DF_ManagmentStructureLevelAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT            CONSTRAINT [DF_ManagmentStructureLevelAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [TypeName]                       NVARCHAR (MAX) NULL,
    [LegalEntityId]                  BIGINT         NULL,
    CONSTRAINT [PK_ManagmentStructureLevelAudit] PRIMARY KEY CLUSTERED ([ManagmentStructureLevelAuditID] ASC)
);


CREATE TABLE [dbo].[ProvisionAudit] (
    [ProvisionAuditId] INT            IDENTITY (1, 1) NOT NULL,
    [ProvisionId]      INT            NOT NULL,
    [Description]      VARCHAR (100)  NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  NOT NULL,
    [IsActive]         BIT            NOT NULL,
    [IsDeleted]        BIT            NOT NULL,
    [StatusCode]       VARCHAR (20)   NULL
);


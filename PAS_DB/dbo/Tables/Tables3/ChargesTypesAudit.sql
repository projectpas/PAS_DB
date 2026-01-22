CREATE TABLE [dbo].[ChargesTypesAudit] (
    [AuditChargesTypesId] INT            IDENTITY (1, 1) NOT NULL,
    [Id]                  INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME       NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    [Name]                VARCHAR (50)   NOT NULL,
    [Description]         VARCHAR (MAX)  NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [IsActive]            BIT            NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    CONSTRAINT [PK_AuditChargestypes] PRIMARY KEY CLUSTERED ([AuditChargesTypesId] ASC)
);


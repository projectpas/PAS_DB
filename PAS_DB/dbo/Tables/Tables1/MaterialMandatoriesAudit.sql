CREATE TABLE [dbo].[MaterialMandatoriesAudit] (
    [MaterialMandatoriesAuditId] INT          IDENTITY (1, 1) NOT NULL,
    [Id]                         INT          NOT NULL,
    [CreatedBy]                  VARCHAR (50) NULL,
    [CreatedDate]                DATETIME     NOT NULL,
    [UpdatedBy]                  VARCHAR (50) NULL,
    [UpdatedDate]                DATETIME     NULL,
    [IsDeleted]                  BIT          NULL,
    [Name]                       VARCHAR (50) NULL,
    [IsActive]                   BIT          NULL,
    [MasterCompanyId]            BIGINT       NOT NULL,
    CONSTRAINT [PK_MaterialMandatoriesAudit] PRIMARY KEY CLUSTERED ([MaterialMandatoriesAuditId] ASC)
);


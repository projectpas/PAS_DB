CREATE TABLE [dbo].[MasterSalesProbablityAudit] (
    [MasterSalesProbablityAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [Id]                           INT           NOT NULL,
    [Value]                        INT           NOT NULL,
    [Description]                  VARCHAR (250) NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (50)  NOT NULL,
    [CreatedDate]                  DATETIME      NOT NULL,
    [UpdatedBy]                    VARCHAR (50)  NULL,
    [UpdatedDate]                  DATETIME      NULL,
    CONSTRAINT [PK_MasterSalesProbablityAudit] PRIMARY KEY CLUSTERED ([MasterSalesProbablityAuditId] ASC)
);


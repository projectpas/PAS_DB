CREATE TABLE [dbo].[ExclusionsAudit] (
    [ExclusionsAuditId]         INT            IDENTITY (1, 1) NOT NULL,
    [Id]                        INT            NOT NULL,
    [CreatedBy]                 VARCHAR (50)   NULL,
    [CreatedDate]               DATETIME       NOT NULL,
    [UpdatedBy]                 VARCHAR (50)   NULL,
    [UpdatedDate]               DATETIME       NULL,
    [IsDeleted]                 BIT            NULL,
    [EPN]                       VARCHAR (256)  NULL,
    [EPNDescription]            VARCHAR (256)  NULL,
    [UnitCost]                  VARCHAR (256)  NULL,
    [Quantity]                  VARCHAR (256)  NULL,
    [Extended]                  VARCHAR (256)  NULL,
    [EstimatedPercentOccurance] VARCHAR (256)  NULL,
    [Memo]                      NVARCHAR (MAX) NULL,
    [ActionId]                  BIGINT         NOT NULL,
    [WorkFlowId]                BIGINT         NOT NULL,
    [IsActive]                  BIT            NULL,
    CONSTRAINT [PK_ExclusionsAudit] PRIMARY KEY CLUSTERED ([ExclusionsAuditId] ASC)
);


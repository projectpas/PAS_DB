CREATE TABLE [dbo].[DirectionsAudit] (
    [DirectionsAuditId] INT            IDENTITY (1, 1) NOT NULL,
    [Id]                INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedBy]         VARCHAR (50)   NULL,
    [UpdatedDate]       DATETIME2 (7)  NULL,
    [IsDeleted]         BIT            NULL,
    [Action]            VARCHAR (256)  NULL,
    [Description]       VARCHAR (256)  NULL,
    [Sequence]          VARCHAR (256)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [ActionId]          BIGINT         NOT NULL,
    [WorkFlowId]        BIGINT         NOT NULL,
    [IsActive]          BIT            NOT NULL,
    CONSTRAINT [PK_DirectionsAudit] PRIMARY KEY CLUSTERED ([DirectionsAuditId] ASC)
);


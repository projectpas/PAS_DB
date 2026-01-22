CREATE TABLE [dbo].[ActivityTypeAudit] (
    [AuditActivityTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ActivityTypeId]      BIGINT        NOT NULL,
    [ActivityTypeName]    VARCHAR (256) NOT NULL,
    [Sequence]            INT           NOT NULL,
    [Points]              INT           NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) NOT NULL,
    [IsActive]            BIT           NOT NULL,
    [IsDeleted]           BIT           NOT NULL,
    CONSTRAINT [PK_ActivityTypeAudit] PRIMARY KEY CLUSTERED ([AuditActivityTypeId] ASC)
);


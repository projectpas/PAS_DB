CREATE TABLE [dbo].[CapabilityTypeAudit] (
    [AuditCapabilityTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CapabilityTypeId]      INT            NOT NULL,
    [Description]           VARCHAR (50)   NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [SequenceMemo]          NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [SequenceNo]            INT            NOT NULL,
    [CapabilityTypeDesc]    VARCHAR (256)  NULL,
    [WorkScopeId]           BIGINT         NULL,
    [ConditionId]           INT            NULL,
    CONSTRAINT [PK_CapabilityTypeAudit] PRIMARY KEY CLUSTERED ([AuditCapabilityTypeId] ASC)
);




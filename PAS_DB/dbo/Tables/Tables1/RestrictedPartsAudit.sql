CREATE TABLE [dbo].[RestrictedPartsAudit] (
    [RestrictedPartAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RestrictedPartId]      BIGINT         NOT NULL,
    [ModuleId]              BIGINT         NOT NULL,
    [ReferenceId]           BIGINT         NOT NULL,
    [ItemMasterId]          BIGINT         NOT NULL,
    [PartNumber]            VARCHAR (100)  NULL,
    [PartType]              VARCHAR (20)   NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [CreatedBy]             VARCHAR (256)  NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NULL,
    [IsActive]              BIT            NULL,
    [IsDeleted]             BIT            NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_RestrictedPartsAudit] PRIMARY KEY CLUSTERED ([RestrictedPartAuditId] ASC)
);


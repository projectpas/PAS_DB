CREATE TABLE [dbo].[SubComponentAudit] (
    [SubComponentAuditId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [SubComponentId]        BIGINT         NULL,
    [ItemMasterId]          BIGINT         NULL,
    [MappingItemMasterId]   BIGINT         NULL,
    [Quantity]              BIGINT         NULL,
    [ConditionId]           BIGINT         NULL,
    [WorkscopeId]           BIGINT         NULL,
    [IsAutoCreateStockline] BIT            NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NULL,
    [CreatedBy]             VARCHAR (256)  NULL,
    [CreatedDate]           DATETIME2 (7)  NULL,
    [UpdatedBy]             VARCHAR (256)  NULL,
    [UpdatedDate]           DATETIME2 (7)  NULL,
    [IsActive]              BIT            NULL,
    [IsDeleted]             BIT            NULL,
    CONSTRAINT [PK_SubComponentAudit] PRIMARY KEY CLUSTERED ([SubComponentAuditId] ASC)
);


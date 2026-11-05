CREATE TABLE [dbo].[LeaseStockLineNoteHistoryAudit] (
    [LeaseStockLineNoteHistoryAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [LeaseStockLineNoteHistoryId]      BIGINT         NULL,
    [LeaseStocklineId]                 BIGINT         NULL,
    [Description]                      NVARCHAR (MAX) NULL,
    [EnteredBy]                        VARCHAR (256)  NULL,
    [CreatedDate]                      DATETIME2 (7)  NULL,
    [EditedBy]                         VARCHAR (256)  NULL,
    [UpdatedDate]                      DATETIME2 (7)  NULL,
    [MasterCompanyId]                  INT            NULL,
    [IsActive]                         BIT            NULL,
    [IsDeleted]                        BIT            NULL,
    CONSTRAINT [PK_LeaseStockLineNoteHistoryAudit] PRIMARY KEY CLUSTERED ([LeaseStockLineNoteHistoryAuditId] ASC)
);


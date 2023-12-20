CREATE TABLE [dbo].[WorkOrderQuoteStatusAudit] (
    [WorkOrderQuoteStatusAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteStatusId]      BIGINT         NOT NULL,
    [Description]                 VARCHAR (50)   NOT NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  NOT NULL,
    [IsActive]                    BIT            NOT NULL,
    [IsDeleted]                   BIT            NOT NULL,
    CONSTRAINT [PK_WorkOrderQuoteStatusAudit] PRIMARY KEY CLUSTERED ([WorkOrderQuoteStatusAuditId] ASC)
);


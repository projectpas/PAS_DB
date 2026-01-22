CREATE TABLE [dbo].[WorkOrderQuoteLaborHeaderAudit] (
    [WorkOrderQuoteLaborHeaderAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteLaborHeaderId]      BIGINT        NOT NULL,
    [WorkOrderQuoteDetailsId]          BIGINT        NOT NULL,
    [DataEnteredBy]                    BIGINT        NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NOT NULL,
    [UpdatedBy]                        VARCHAR (256) NOT NULL,
    [CreatedDate]                      DATETIME2 (7) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) NOT NULL,
    [IsActive]                         BIT           NOT NULL,
    [IsDeleted]                        BIT           NOT NULL,
    [MarkupFixedPrice]                 VARCHAR (15)  NULL,
    [HeaderMarkupId]                   BIGINT        NULL,
    CONSTRAINT [PK_WorkOrderQuoteLaborHeaderAudit] PRIMARY KEY CLUSTERED ([WorkOrderQuoteLaborHeaderAuditId] ASC)
);


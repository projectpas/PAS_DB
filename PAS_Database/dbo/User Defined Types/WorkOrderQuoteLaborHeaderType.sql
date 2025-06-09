CREATE TYPE [dbo].[WorkOrderQuoteLaborHeaderType] AS TABLE (
    [WorkOrderQuoteLaborHeaderId] BIGINT        NULL,
    [WorkOrderQuoteDetailsId]     BIGINT        NULL,
    [DataEnteredBy]               BIGINT        NULL,
    [MasterCompanyId]             INT           NULL,
    [CreatedBy]                   VARCHAR (256) NULL,
    [UpdatedBy]                   VARCHAR (256) NULL,
    [CreatedDate]                 DATETIME2 (7) NULL,
    [UpdatedDate]                 DATETIME2 (7) NULL,
    [IsActive]                    BIT           NULL,
    [IsDeleted]                   BIT           NULL,
    [MarkupFixedPrice]            VARCHAR (15)  NULL,
    [HeaderMarkupId]              BIGINT        NULL);


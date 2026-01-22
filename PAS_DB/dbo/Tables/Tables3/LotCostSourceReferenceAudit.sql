CREATE TABLE [dbo].[LotCostSourceReferenceAudit] (
    [LotSourceAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [LotSourceId]      INT           NULL,
    [SourceName]       VARCHAR (50)  NOT NULL,
    [Code]             VARCHAR (20)  NULL,
    [SequenceNo]       INT           NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NULL,
    [IsActive]         BIT           NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    CONSTRAINT [PK_LotCostSourceReferenceAudit] PRIMARY KEY CLUSTERED ([LotSourceAuditId] ASC)
);


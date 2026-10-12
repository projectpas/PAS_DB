CREATE TABLE [dbo].[CycleCountSettingPrintFieldAudit] (
    [CycleCountSettingPrintFieldAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CycleCountSettingPrintFieldId]      BIGINT        NOT NULL,
    [CycleCountSettingId]                BIGINT        NOT NULL,
    [CountMethodId]                      INT           NOT NULL,
    [FieldKey]                           VARCHAR (50)  NOT NULL,
    [IsSelected]                         BIT           NOT NULL,
    [SequenceNo]                         INT           NULL,
    [MasterCompanyId]                    INT           NOT NULL,
    [CreatedBy]                          VARCHAR (256) NOT NULL,
    [UpdatedBy]                          VARCHAR (256) NOT NULL,
    [CreatedDate]                        DATETIME2 (7) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7) NOT NULL,
    [IsActive]                           BIT           NOT NULL,
    [IsDeleted]                          BIT           NOT NULL,
    CONSTRAINT [PK_CycleCountSettingPrintFieldAudit] PRIMARY KEY CLUSTERED ([CycleCountSettingPrintFieldAuditId] ASC)
);

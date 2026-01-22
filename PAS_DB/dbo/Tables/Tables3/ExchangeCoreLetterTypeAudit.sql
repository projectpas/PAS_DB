CREATE TABLE [dbo].[ExchangeCoreLetterTypeAudit] (
    [ExchangeCoreLetterTypeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ExchangeCoreLetterTypeId]      BIGINT        NOT NULL,
    [Name]                          VARCHAR (50)  NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (50)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_ExchangeCoreLetterTypeAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                     VARCHAR (50)  NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) CONSTRAINT [DF_ExchangeCoreLetterTypeAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT           CONSTRAINT [DF__ExchangeCoreLetterTypeAudit__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT           CONSTRAINT [DF__ExchangeCoreLetterTypeAudit__IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]                    INT           NULL,
    CONSTRAINT [PK_ExchangeCoreLetterTypeAudit] PRIMARY KEY CLUSTERED ([ExchangeCoreLetterTypeAuditId] ASC)
);


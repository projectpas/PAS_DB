CREATE TABLE [dbo].[GLAccountLadgerMappingAudit] (
    [GLAccountLadgerMapperAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [GLAccountLadgerMapperId]      BIGINT        NOT NULL,
    [GlAccountId]                  BIGINT        NOT NULL,
    [LedgerId]                     BIGINT        NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_GLAccountLadgerMappingAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) CONSTRAINT [DF_GLAccountLadgerMappingAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [DF_GLAccountLadgerMappingAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT           NOT NULL,
    CONSTRAINT [PK_GLAccountLadgerMappingAudit] PRIMARY KEY CLUSTERED ([GLAccountLadgerMapperAuditId] ASC)
);


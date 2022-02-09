CREATE TABLE [dbo].[WorkOrderQuoteSettingsAudit] (
    [WorkOrderQuoteSettingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteSettingId]      BIGINT        NOT NULL,
    [WorkOrderTypeId]              INT           NOT NULL,
    [Prefix]                       VARCHAR (10)  NOT NULL,
    [Sufix]                        VARCHAR (10)  NULL,
    [StartCode]                    BIGINT        NOT NULL,
    [ValidDays]                    INT           NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) NOT NULL,
    [IsActive]                     BIT           NOT NULL,
    [IsDeleted]                    BIT           NOT NULL,
    [CurrentNumber]                BIGINT        DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]               BIT           NULL,
    [effectivedate]                DATETIME      NULL,
    [TearDownTypes]                VARCHAR (50)  NULL,
    CONSTRAINT [PK_WorkOrderQuoteSettingsAudit] PRIMARY KEY CLUSTERED ([WorkOrderQuoteSettingAuditId] ASC)
);




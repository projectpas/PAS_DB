CREATE TABLE [dbo].[AiIntegrationSetting] (
    [AiIntegrationSettingId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [IsEnableDisableAIintegration] BIT             NOT NULL,
    [IsReviewRequired]             BIT             NULL,
    [IsAutoEmailSend]              BIT             NULL,
    [PercentId]                    BIGINT          NULL,
    [PercentValue]                 DECIMAL (18, 2) NULL,
    [MasterCompanyId]              INT             NOT NULL,
    [CreatedBy]                    VARCHAR (256)   NOT NULL,
    [UpdatedBy]                    VARCHAR (256)   NOT NULL,
    [CreatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_AiIntegrationSetting_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_AiIntegrationSetting_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT             CONSTRAINT [DF_AiIntegrationSetting_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT             CONSTRAINT [DF_AiIntegrationSetting_IsDeleted] DEFAULT ((0)) NOT NULL,
    [YearId]                       BIGINT          NULL,
    [MonthId]                      BIGINT          NULL,
    [IsAutoInternalQuote]          BIT             NULL,
    [OpenAIAPIKeys]                NVARCHAR (MAX)  NULL,
    [DocumentTypeId] NVARCHAR(250) NULL, 
    CONSTRAINT [PK_AiIntegrationSetting] PRIMARY KEY CLUSTERED ([AiIntegrationSettingId] ASC)
);




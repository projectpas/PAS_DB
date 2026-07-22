CREATE TABLE [dbo].[AISettingMaster] (
    [AISettingId]     INT            IDENTITY (1, 1) NOT NULL,
    [MasterCompanyId] INT            DEFAULT ((0)) NOT NULL,
    [Provider]        VARCHAR (32)   DEFAULT ('anthropic') NOT NULL,
    [MaxTokens]       INT            DEFAULT ((4096)) NOT NULL,
    [Temperature]     DECIMAL (4, 2) DEFAULT ((0.20)) NOT NULL,
    [OpenAIModel]     VARCHAR (128)  NULL,
    [OpenAIApiKey]    NVARCHAR (512) NULL,
    [AnthropicModel]  VARCHAR (128)  NULL,
    [AnthropicApiKey] NVARCHAR (512) NULL,
    [IsActive]        BIT            DEFAULT ((1)) NOT NULL,
    [CreatedBy]       NVARCHAR (100) DEFAULT ('system') NOT NULL,
    [CreatedDate]     DATETIME       DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       NVARCHAR (100) DEFAULT ('system') NOT NULL,
    [UpdatedDate]     DATETIME       DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_AISettingMaster] PRIMARY KEY CLUSTERED ([AISettingId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_AISettingMaster_Company]
    ON [dbo].[AISettingMaster]([MasterCompanyId] ASC) WHERE ([IsActive]=(1));


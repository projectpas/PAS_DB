CREATE TABLE [dbo].[SpeedQuoteSettings] (
    [SpeedQuoteSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [QuoteTypeId]         INT           NOT NULL,
    [ValidDays]           INT           NOT NULL,
    [Prefix]              VARCHAR (20)  NOT NULL,
    [Sufix]               VARCHAR (20)  NOT NULL,
    [StartCode]           BIGINT        NOT NULL,
    [CurrentNumber]       BIGINT        NOT NULL,
    [DefaultStatusId]     INT           NOT NULL,
    [DefaultPriorityId]   BIGINT        NOT NULL,
    [SQListViewId]        INT           NOT NULL,
    [SQListStatusId]      INT           NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_SpeedQuoteSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_SpeedQuoteSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_SpeedQuoteSettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_SpeedQuoteSettings_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]      BIT           NULL,
    [EffectiveDate]       DATETIME2 (7) NULL,
    CONSTRAINT [PK_SpeedQuoteSettings] PRIMARY KEY CLUSTERED ([SpeedQuoteSettingId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_SpeedQuoteSettingsAudit]

   ON  [dbo].[SpeedQuoteSettings]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SpeedQuoteSettingsAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
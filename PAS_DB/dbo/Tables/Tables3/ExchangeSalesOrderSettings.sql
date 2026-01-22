CREATE TABLE [dbo].[ExchangeSalesOrderSettings] (
    [ExchangeSalesOrderSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TypeId]                      INT           NOT NULL,
    [ValidDays]                   INT           NULL,
    [Prefix]                      VARCHAR (20)  NULL,
    [Sufix]                       VARCHAR (20)  NULL,
    [StartCode]                   BIGINT        NULL,
    [CurrentNumber]               BIGINT        NOT NULL,
    [DefaultStatusId]             INT           NOT NULL,
    [DefaultPriorityId]           BIGINT        NOT NULL,
    [SOListViewId]                INT           DEFAULT ((1)) NOT NULL,
    [SOListStatusId]              INT           DEFAULT ((1)) NOT NULL,
    [COGS]                        INT           NOT NULL,
    [DaysForCoreReturn]           INT           NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_ExchangeSalesOrderSettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_ExchangeSalesOrderSettings_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]              BIT           NULL,
    [EffectiveDate]               DATETIME2 (7) NULL,
    [FeesBillingIntervalDays]     INT           NULL,
    [ExpectedConditionId]         BIGINT        NULL,
    CONSTRAINT [PK_ExchangeSalesOrderSettings] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderSettingId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderSettingsAudit]

   ON  [dbo].[ExchangeSalesOrderSettings]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderSettingsAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
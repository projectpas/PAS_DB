CREATE TABLE [dbo].[WorkOrderQuoteSettings] (
    [WorkOrderQuoteSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderTypeId]         BIGINT        NOT NULL,
    [Prefix]                  VARCHAR (10)  NOT NULL,
    [Sufix]                   VARCHAR (10)  NULL,
    [StartCode]               BIGINT        NOT NULL,
    [ValidDays]               INT           NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_WorkOrderQuoteSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_WorkOrderQuoteSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [WorkOrderQuoteSettings_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [WorkOrderQuoteSettings_DC_Delete] DEFAULT ((0)) NOT NULL,
    [CurrentNumber]           BIGINT        DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]          BIT           NULL,
    [effectivedate]           DATETIME      NULL,
    CONSTRAINT [PK_WorkOrderQuoteSettings] PRIMARY KEY CLUSTERED ([WorkOrderQuoteSettingId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteSettings_WorkOrderTypeId] FOREIGN KEY ([WorkOrderTypeId]) REFERENCES [dbo].[WorkOrderType] ([Id])
);


GO






----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteSettingsAudit]

   ON  [dbo].[WorkOrderQuoteSettings]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderQuoteSettingsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
CREATE TABLE [dbo].[WorkOrderSettings] (
    [WorkOrderSettingId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderTypeId]            INT           NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_WorkOrderSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_WorkOrderSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [WorkOrderSettings_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [WorkOrderSettings_DC_Delete] DEFAULT ((0)) NOT NULL,
    [RecivingListDefaultRBId]    BIGINT        NULL,
    [DefaultConditionId]         BIGINT        NULL,
    [DefaultSiteId]              BIGINT        NULL,
    [DefaultWearhouseId]         BIGINT        NULL,
    [DefaultLocationId]          BIGINT        NULL,
    [DefaultShelfId]             BIGINT        NULL,
    [DefaultStageCodeId]         BIGINT        NULL,
    [DefaultScopeId]             BIGINT        NULL,
    [WOListViewRBId]             BIGINT        NULL,
    [DefaultStatusId]            BIGINT        NULL,
    [DefaultPriorityId]          BIGINT        NULL,
    [WOListStatusRBId]           BIGINT        NULL,
    [TearDownTypes]              VARCHAR (50)  NULL,
    [DefaultBinId]               BIGINT        NULL,
    [IsApprovalRule]             BIT           NULL,
    [LaborHoursMedthodId]        BIGINT        NULL,
    [EnforcePickTicket]          BIT           NULL,
    [PickTicketEffectiveDate]    DATETIME2 (7) NULL,
    [Isshortteardown]            BIT           DEFAULT ((0)) NULL,
    [Dualreleaselanguage]        VARCHAR (MAX) NULL,
    [StandardTurntimeDays]       INT           NULL,
    [StandardTurntimecolour]     BIT           NULL,
    [IsTraveler]                 BIT           NULL,
    [IsAutoReserve]              BIT           NULL,
    [IsAutoIssue]                BIT           NULL,
    [IsManualForm]               BIT           NULL,
    [SettingStatusId]            BIGINT        NULL,
    [DefaultProvisionId]         INT           NULL,
    [DefaultTaskId]              BIGINT        NULL,
    [LaborlogoffHours]           INT           NULL,
    [WOStages]                   VARCHAR (50)  NULL,
    [AllowInvoiceBeforeShipping] BIT           NULL,
    CONSTRAINT [PK_WorkOrderSettings] PRIMARY KEY CLUSTERED ([WorkOrderSettingId] ASC),
    CONSTRAINT [FK_WorkOrderSettings_ConditionId] FOREIGN KEY ([DefaultConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO




----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderSettingsAudit]

   ON  [dbo].[WorkOrderSettings]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderSettingsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
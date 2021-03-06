CREATE TABLE [dbo].[WorkOrderSettingsAudit] (
    [AuditWorkOrderSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderSettingId]      BIGINT        NOT NULL,
    [WorkOrderTypeId]         INT           NOT NULL,
    [Prefix]                  VARCHAR (10)  NULL,
    [Sufix]                   VARCHAR (10)  NULL,
    [StartCode]               BIGINT        NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) NOT NULL,
    [IsActive]                BIT           NOT NULL,
    [IsDeleted]               BIT           NOT NULL,
    [RecivingListDefaultRB]   VARCHAR (25)  NULL,
    [DefaultConditionId]      BIGINT        NULL,
    [DefaultSiteId]           BIGINT        NULL,
    [DefaultWearhouseId]      BIGINT        NULL,
    [DefaultLocationId]       BIGINT        NULL,
    [DefaultShelfId]          BIGINT        NULL,
    [DefaultStageCodeId]      BIGINT        NULL,
    [DefaultScopeId]          BIGINT        NULL,
    [WOListViewRBId]          VARCHAR (10)  NULL,
    [DefaultStatusId]         BIGINT        NULL,
    [DefaultPriorityId]       BIGINT        NULL,
    [WOListStatusRBId]        BIGINT        NULL,
    [TearDownTypes]           VARCHAR (50)  NULL,
    [CurrentNumber]           BIGINT        DEFAULT ((0)) NOT NULL,
    [DefaultBinId]            BIGINT        NULL,
    [IsApprovalRule]          BIT           NULL,
    [LaborHoursMedthodId]     BIGINT        NULL,
    [EnforcePickTicket]       BIT           NULL,
    [PickTicketEffectiveDate] DATETIME2 (7) NULL,
    [Isshortteardown]         BIT           DEFAULT ((0)) NULL,
    CONSTRAINT [PK_WorkOrderSettingsAudit] PRIMARY KEY CLUSTERED ([AuditWorkOrderSettingId] ASC)
);


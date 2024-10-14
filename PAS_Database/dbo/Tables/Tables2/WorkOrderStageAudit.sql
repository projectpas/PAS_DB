CREATE TABLE [dbo].[WorkOrderStageAudit] (
    [WorkOrderStageAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderStageId]      BIGINT         NOT NULL,
    [Code]                  VARCHAR (10)   NOT NULL,
    [Stage]                 VARCHAR (100)  NOT NULL,
    [Sequence]              INT            NOT NULL,
    [StatusId]              BIGINT         NOT NULL,
    [Description]           VARCHAR (500)  NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [StageCode]             NVARCHAR (50)  NULL,
    [CodeDescription]       VARCHAR (200)  NULL,
    [IncludeInDashboard]    BIT            DEFAULT ((0)) NULL,
    [ManagerId]             BIGINT         NULL,
    [IsCustAlerts]          BIT            NULL,
    [EmployeeName]          VARCHAR (100)  NULL,
    [IncludeInStageReport]  BIT            NULL,
    [Worked]                BIT            NULL,
    CONSTRAINT [PK_WorkOrderStageAudit] PRIMARY KEY CLUSTERED ([WorkOrderStageAuditId] ASC)
);










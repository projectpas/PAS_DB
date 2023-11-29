CREATE TABLE [dbo].[SubWorkOrderLabor] (
    [SubWorkOrderLaborId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderLaborHeaderId] BIGINT          NOT NULL,
    [TaskId]                    BIGINT          NOT NULL,
    [ExpertiseId]               SMALLINT        NULL,
    [EmployeeId]                BIGINT          NULL,
    [Hours]                     DECIMAL (10, 2) NULL,
    [Adjustments]               DECIMAL (10, 2) NULL,
    [AdjustedHours]             DECIMAL (10, 2) NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [StartDate]                 DATETIME2 (7)   NULL,
    [EndDate]                   DATETIME2 (7)   NULL,
    [BillableId]                INT             NULL,
    [IsFromWorkFlow]            BIT             DEFAULT ((0)) NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderLabor_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderLabor_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [SubWorkOrderLabor_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [SubWorkOrderLabor_DC_Delete] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]           INT             NULL,
    [DirectLaborOHCost]         DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [BurdaenRatePercentageId]   BIGINT          NULL,
    [BurdenRateAmount]          DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TotalCostPerHour]          DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TotalCost]                 DECIMAL (18, 2) DEFAULT ((0)) NOT NULL,
    [TaskStatusId]              BIGINT          NULL,
    [StatusChangedDate]         DATETIME2 (7)   NULL,
    [TaskInstruction]           VARCHAR (MAX)   NULL,
    [IsBegin]                   BIT             NULL,
    CONSTRAINT [PK_SubWorkOrderLabor] PRIMARY KEY CLUSTERED ([SubWorkOrderLaborId] ASC),
    CONSTRAINT [FK_SubWorkOrderLabor_BurdaenRatePercentageId] FOREIGN KEY ([BurdaenRatePercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_SubWorkOrderLabor_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SubWorkOrderLabor_ExpertiseId] FOREIGN KEY ([ExpertiseId]) REFERENCES [dbo].[EmployeeExpertise] ([EmployeeExpertiseId]),
    CONSTRAINT [FK_SubWorkOrderLabor_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderLabor_SubWorkOrderLaborHeader] FOREIGN KEY ([SubWorkOrderLaborHeaderId]) REFERENCES [dbo].[SubWorkOrderLaborHeader] ([SubWorkOrderLaborHeaderId]),
    CONSTRAINT [FK_SubWorkOrderLabor_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_SubWorkOrderLabor_TaskStatusId] FOREIGN KEY ([TaskStatusId]) REFERENCES [dbo].[TaskStatus] ([TaskStatusId])
);




GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderLaborAudit]

   ON  [dbo].[SubWorkOrderLabor]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderLaborAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END
CREATE TABLE [dbo].[SubWorkOrderLabor] (
    [SubWorkOrderLaborId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderLaborHeaderId] BIGINT          NOT NULL,
    [TaskId]                    BIGINT          NOT NULL,
    [ExpertiseId]               SMALLINT        NULL,
    [EmployeeId]                BIGINT          NULL,
    [Hours]                     DECIMAL (18, 6) CONSTRAINT [DF_SubWorkOrderLabor_Hours] DEFAULT ((0)) NULL,
    [Adjustments]               DECIMAL (18, 6) CONSTRAINT [DF_SubWorkOrderLabor_Adjustments] DEFAULT ((0)) NULL,
    [AdjustedHours]             DECIMAL (18, 6) CONSTRAINT [DF_SubWorkOrderLabor_AdjustedHours] DEFAULT ((0)) NULL,
    [StandardHours]             DECIMAL (18, 6) CONSTRAINT [DF_SubWorkOrderLabor_StandardHours] DEFAULT ((0)) NULL,
    [StandardMinute]            DECIMAL (18, 6) CONSTRAINT [DF_SubWorkOrderLabor_StandardMinute] DEFAULT ((0)) NULL,
    [VarianceHours]             DECIMAL (18, 6) CONSTRAINT [DF_SubWorkOrderLabor_VarianceHours] DEFAULT ((0)) NULL,
    [VarianceMinute]            DECIMAL (18, 6) CONSTRAINT [DF_SubWorkOrderLabor_VarianceMinute] DEFAULT ((0)) NULL,
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
    [DirectLaborOHCost]         DECIMAL (18, 6) CONSTRAINT [DF__tmp_ms_xx__Direc__2D4C77A4] DEFAULT ((0)) NULL,
    [BurdaenRatePercentageId]   BIGINT          NULL,
    [BurdenRateAmount]          DECIMAL (18, 6) CONSTRAINT [DF__tmp_ms_xx__Burde__2E409BDD] DEFAULT ((0)) NULL,
    [TotalCostPerHour]          DECIMAL (18, 6) CONSTRAINT [DF__tmp_ms_xx__Total__2F34C016] DEFAULT ((0)) NULL,
    [TotalCost]                 DECIMAL (18, 6) CONSTRAINT [DF__tmp_ms_xx__Total__3028E44F] DEFAULT ((0)) NULL,
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
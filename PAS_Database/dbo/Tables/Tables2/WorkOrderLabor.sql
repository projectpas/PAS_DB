CREATE TABLE [dbo].[WorkOrderLabor] (
    [WorkOrderLaborId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderLaborHeaderId]  BIGINT          NOT NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [ExpertiseId]             SMALLINT        NULL,
    [EmployeeId]              BIGINT          NULL,
    [Hours]                   DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderLabor_Hours] DEFAULT ((0)) NULL,
    [Adjustments]             DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderLabor_Adjustments] DEFAULT ((0)) NULL,
    [AdjustedHours]           DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderLabor_AdjustedHours] DEFAULT ((0)) NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderLabor_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderLabor_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [WorkOrderLabor_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [WorkOrderLabor_DC_Delete] DEFAULT ((0)) NOT NULL,
    [StartDate]               DATETIME2 (7)   NULL,
    [EndDate]                 DATETIME2 (7)   NULL,
    [BillableId]              INT             NULL,
    [IsFromWorkFlow]          BIT             CONSTRAINT [DF__WorkOrder__IsFro__0762CD2B] DEFAULT ((0)) NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [DirectLaborOHCost]       DECIMAL (18, 2) CONSTRAINT [DF__WorkOrder__Direc__0856F164] DEFAULT ((0)) NOT NULL,
    [BurdaenRatePercentageId] BIGINT          NULL,
    [BurdenRateAmount]        DECIMAL (18, 2) CONSTRAINT [DF__WorkOrder__Burde__094B159D] DEFAULT ((0)) NULL,
    [TotalCostPerHour]        DECIMAL (18, 2) CONSTRAINT [DF__WorkOrder__Total__0A3F39D6] DEFAULT ((0)) NOT NULL,
    [TotalCost]               DECIMAL (18, 2) CONSTRAINT [DF__WorkOrder__Total__0B335E0F] DEFAULT ((0)) NOT NULL,
    [TaskStatusId]            BIGINT          NULL,
    [StatusChangedDate]       DATETIME2 (7)   NULL,
    [TaskInstruction]         VARCHAR (MAX)   NULL,
    [IsBegin]                 BIT             NULL,
    CONSTRAINT [PK_WorkOrderLabor] PRIMARY KEY CLUSTERED ([WorkOrderLaborId] ASC),
    CONSTRAINT [FK_WorkOrderLabor_BurdaenRatePercentageId] FOREIGN KEY ([BurdaenRatePercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_WorkOrderLabor_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderLabor_ExpertiseId] FOREIGN KEY ([ExpertiseId]) REFERENCES [dbo].[EmployeeExpertise] ([EmployeeExpertiseId]),
    CONSTRAINT [FK_WorkOrderLabor_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderLabor_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderLabor_TaskStatusId] FOREIGN KEY ([TaskStatusId]) REFERENCES [dbo].[TaskStatus] ([TaskStatusId]),
    CONSTRAINT [FK_WorkOrderLabor_WorkOrderLaborHeader] FOREIGN KEY ([WorkOrderLaborHeaderId]) REFERENCES [dbo].[WorkOrderLaborHeader] ([WorkOrderLaborHeaderId])
);


GO
----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderLaborAudit]

   ON  dbo.WorkOrderLabor

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE @TaskId BIGINT, @ExpertiseId BIGINT,@EmployeeId BIGINT

	



	DECLARE @Task VARCHAR(256), @Expertise VARCHAR(256),@Employee VARCHAR(256),@Billable VARCHAR(10)



	SELECT @TaskId=TaskId, @ExpertiseId=ExpertiseId,@EmployeeId=EmployeeId,

	@Billable=CASE WHEN BillableId=1 THEN 'Yes' ELSE 'No' END

	FROM INSERTED

	

	SELECT @Task=Description FROM Task WHERE TaskId=@TaskId

	SELECT @Expertise=Description FROM EmployeeExpertise WHERE EmployeeExpertiseId=@ExpertiseId

	SELECT @Employee=FirstName+' '+LastName FROM Employee WHERE EmployeeId=@EmployeeId

	



INSERT INTO [dbo].[WorkOrderLaborAudit]

           ([WorkOrderLaborId]

           ,[WorkOrderLaborAuditHeaderId]

           ,[TaskId]

           ,[ExpertiseId]

           ,[EmployeeId]

           ,[Hours]

           ,[Adjustments]

           ,[AdjustedHours]

           ,[Memo]

           ,[CreatedBy]

           ,[UpdatedBy]

           ,[CreatedDate]

           ,[UpdatedDate]

           ,[IsActive]

           ,[IsDeleted]

           ,[StartDate]

           ,[EndDate]

           ,[BillableId]

           ,[IsFromWorkFlow]

           ,[MasterCompanyId]

           ,[TaskName]

           ,[LabourExpertise]

           ,[LabourEmployee]

           ,[Billable]

           ,[DirectLaborOHCost]

           ,[BurdaenRatePercentageId]

           ,[BurdenRateAmount]

           ,[TotalCostPerHour]

           ,[TotalCost]

		   ,TaskStatusId

		   ,StatusChangedDate)

    SELECT [WorkOrderLaborId]

           ,[WorkOrderLaborHeaderId]

           ,[TaskId]

           ,[ExpertiseId]

           ,[EmployeeId]

           ,[Hours]

           ,[Adjustments]

           ,[AdjustedHours]

           ,[Memo]

           ,[CreatedBy]

           ,[UpdatedBy]

           ,[CreatedDate]

           ,[UpdatedDate]

           ,[IsActive]

           ,[IsDeleted]

           ,[StartDate]

           ,[EndDate]

           ,[BillableId]

           ,[IsFromWorkFlow]

           ,[MasterCompanyId]

           ,@Task

           ,@Expertise

           ,@Employee

           ,@Billable

           ,[DirectLaborOHCost]

           ,[BurdaenRatePercentageId]

           ,[BurdenRateAmount]

           ,[TotalCostPerHour]

           ,[TotalCost]

		   ,TaskStatusId

		   ,StatusChangedDate

	FROM INSERTED 

	SET NOCOUNT ON;



END
CREATE TABLE [dbo].[WorkOrderLaborHeader] (
    [WorkOrderLaborHeaderId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]            BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]    BIGINT          NOT NULL,
    [DataEnteredBy]          BIGINT          NOT NULL,
    [HoursorClockorScan]     INT             NULL,
    [IsTaskCompletedByOne]   BIT             NULL,
    [WorkOrderHoursType]     INT             NULL,
    [LabourMemo]             NVARCHAR (MAX)  NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_WorkOrderLaborHeader_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_WorkOrderLaborHeader_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [WorkOrderLaborHeader_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [WorkOrderLaborHeader_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ExpertiseId]            SMALLINT        NULL,
    [EmployeeId]             BIGINT          NULL,
    [TotalWorkHours]         DECIMAL (20, 2) NULL,
    [WOPartNoId]             BIGINT          DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderLaborHeader] PRIMARY KEY CLUSTERED ([WorkOrderLaborHeaderId] ASC),
    CONSTRAINT [FK_WorkOrderLaborHeader_DataEnteredBy] FOREIGN KEY ([DataEnteredBy]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderLaborHeader_EmployeeExpertise] FOREIGN KEY ([ExpertiseId]) REFERENCES [dbo].[EmployeeExpertise] ([EmployeeExpertiseId]),
    CONSTRAINT [FK_WorkOrderLaborHeader_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderLaborHeader_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderLaborHeader_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderLaborHeader_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderLaborHeaderAudit]

   ON  [dbo].[WorkOrderLaborHeader]

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE  @ExpertiseId BIGINT,@EmployeeId BIGINT,@DataEnteredById BIGINT

	



	DECLARE @Expertise VARCHAR(256),@Employee VARCHAR(256),@DataEnteredByName VARCHAR(256),@HoursType VARCHAR(50),

	@TaskCompletedBy  VARCHAR(10),@TaskType  VARCHAR(256) 



	SELECT @ExpertiseId=ExpertiseId,@EmployeeId=EmployeeId,@DataEnteredById=DataEnteredBy,

	@HoursType=CASE WHEN HoursorClockorScan=1 THEN 'Labour Hours'

	WHEN HoursorClockorScan=2 THEN 'Labour Clock In/Out'

	WHEN HoursorClockorScan=3 THEN 'Scan' ELSE '' END,

	@TaskCompletedBy=CASE WHEN IsTaskCompletedByOne=1 THEN 'Yes' ELSE 'No' END,

	@TaskType=CASE WHEN WorkOrderHoursType=1 THEN 'Workflow'

	WHEN WorkOrderHoursType=2 THEN 'Specific Tasks'

	WHEN WorkOrderHoursType=3 THEN 'Work Order' ELSE '' END

	FROM INSERTED

	

	SELECT @Expertise=Description FROM EmployeeExpertise WHERE EmployeeExpertiseId=@ExpertiseId

	SELECT @Employee=FirstName+' '+LastName FROM Employee WHERE EmployeeId=@EmployeeId

	SELECT @DataEnteredByName=FirstName+' '+LastName FROM Employee WHERE EmployeeId=@DataEnteredById



	INSERT INTO [dbo].[WorkOrderLaborHeaderAudit] 

    SELECT *, @Expertise,@Employee,@DataEnteredByName,@HoursType,@TaskCompletedBy,@TaskType

	FROM INSERTED 

	SET NOCOUNT ON;



END
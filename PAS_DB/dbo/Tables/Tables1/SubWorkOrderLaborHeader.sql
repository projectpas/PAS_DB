CREATE TABLE [dbo].[SubWorkOrderLaborHeader] (
    [SubWorkOrderLaborHeaderId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]               BIGINT          NOT NULL,
    [SubWorkOrderId]            BIGINT          NOT NULL,
    [SubWOPartNoId]             BIGINT          NOT NULL,
    [DataEnteredBy]             BIGINT          NOT NULL,
    [HoursorClockorScan]        INT             NULL,
    [IsTaskCompletedByOne]      BIT             NULL,
    [WorkOrderHoursType]        INT             NULL,
    [LabourMemo]                NVARCHAR (MAX)  NULL,
    [ExpertiseId]               SMALLINT        NULL,
    [EmployeeId]                BIGINT          NOT NULL,
    [TotalWorkHours]            DECIMAL (20, 2) NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderLaborHeader_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderLaborHeader_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [SubWorkOrderLaborHeader_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [SubWorkOrderLaborHeader_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWorkOrderLaborHeader] PRIMARY KEY CLUSTERED ([SubWorkOrderLaborHeaderId] ASC),
    CONSTRAINT [FK_SubWorkOrderLaborHeader_DataEnteredBy] FOREIGN KEY ([DataEnteredBy]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SubWorkOrderLaborHeader_EmployeeExpertise] FOREIGN KEY ([ExpertiseId]) REFERENCES [dbo].[EmployeeExpertise] ([EmployeeExpertiseId]),
    CONSTRAINT [FK_SubWorkOrderLaborHeader_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SubWorkOrderLaborHeader_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderLaborHeader_SubWOPartNo] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderLaborHeader_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderLaborHeader_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderLaborHeaderAudit]

   ON  [dbo].[SubWorkOrderLaborHeader]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderLaborHeaderAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END
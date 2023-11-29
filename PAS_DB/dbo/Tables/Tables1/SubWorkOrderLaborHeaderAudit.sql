CREATE TABLE [dbo].[SubWorkOrderLaborHeaderAudit] (
    [SubWorkOrderLaborHeaderAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderLaborHeaderId]      BIGINT          NOT NULL,
    [WorkOrderId]                    BIGINT          NOT NULL,
    [SubWorkOrderId]                 BIGINT          NOT NULL,
    [SubWOPartNoId]                  BIGINT          NOT NULL,
    [DataEnteredBy]                  BIGINT          NOT NULL,
    [HoursorClockorScan]             INT             NULL,
    [IsTaskCompletedByOne]           BIT             NULL,
    [WorkOrderHoursType]             INT             NULL,
    [LabourMemo]                     NVARCHAR (MAX)  NULL,
    [ExpertiseId]                    SMALLINT        NULL,
    [EmployeeId]                     BIGINT          NULL,
    [TotalWorkHours]                 DECIMAL (20, 2) NULL,
    [MasterCompanyId]                INT             NOT NULL,
    [CreatedBy]                      VARCHAR (256)   NOT NULL,
    [UpdatedBy]                      VARCHAR (256)   NOT NULL,
    [CreatedDate]                    DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   NOT NULL,
    [IsActive]                       BIT             NOT NULL,
    [IsDeleted]                      BIT             NOT NULL,
    CONSTRAINT [PK_SubWorkOrderLaborHeaderAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderLaborHeaderAuditId] ASC)
);




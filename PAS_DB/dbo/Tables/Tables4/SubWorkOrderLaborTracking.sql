CREATE TABLE [dbo].[SubWorkOrderLaborTracking] (
    [SubWorkOrderLaborTrackingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderLaborId]         BIGINT        NULL,
    [TaskId]                      BIGINT        NULL,
    [EmployeeId]                  BIGINT        NULL,
    [StartTime]                   DATETIME2 (7) NULL,
    [EndTime]                     DATETIME2 (7) NULL,
    [TotalHours]                  INT           NULL,
    [TotalMinutes]                INT           NULL,
    [IsCompleted]                 BIT           NULL,
    [MasterCompanyId]             INT           NULL,
    [CreatedBy]                   VARCHAR (255) NULL,
    [UpdatedBy]                   VARCHAR (255) NULL,
    [CreatedDate]                 DATETIME2 (7) NULL,
    [UpdatedDate]                 DATETIME2 (7) NULL,
    [IsActive]                    BIT           NULL,
    [IsDeleted]                   BIT           NULL,
    CONSTRAINT [PK_SubWorkOrderLaborTracking] PRIMARY KEY CLUSTERED ([SubWorkOrderLaborTrackingId] ASC)
);


﻿CREATE TABLE [dbo].[EmployeeTrainingAudit] (
    [EmployeeTrainingAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [EmployeeTrainingId]      BIGINT          NOT NULL,
    [EmployeeId]              BIGINT          NOT NULL,
    [AircraftModelId]         BIGINT          NULL,
    [EmployeeTrainingTypeId]  BIGINT          NOT NULL,
    [ScheduleDate]            DATETIME2 (7)   NULL,
    [CompletionDate]          DATETIME2 (7)   NULL,
    [Cost]                    NUMERIC (18, 2) NULL,
    [Duration]                INT             NULL,
    [Provider]                VARCHAR (30)    NULL,
    [IndustryCode]            VARCHAR (30)    NULL,
    [ExpirationDate]          DATETIME2 (7)   NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_EmployeeTrainingAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_EmployeeTrainingAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_EmployeeTrainingAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [FrequencyOfTrainingId]   BIGINT          NULL,
    [AircraftManufacturerId]  INT             NULL,
    [DurationTypeId]          INT             NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_EmployeeTrainingAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeTrainingAudit] PRIMARY KEY CLUSTERED ([EmployeeTrainingAuditId] ASC)
);


CREATE TABLE [dbo].[EmployeeStationAudit] (
    [AuditEmployeeStationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmployeeStationId]      BIGINT         NOT NULL,
    [StationName]            VARCHAR (100)  NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedDate]            DATETIME2 (7)  NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [IsActive]               BIT            NOT NULL,
    [IsDeleted]              BIT            NOT NULL,
    [Description]            VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_EmployeeStationAudit] PRIMARY KEY CLUSTERED ([AuditEmployeeStationId] ASC)
);


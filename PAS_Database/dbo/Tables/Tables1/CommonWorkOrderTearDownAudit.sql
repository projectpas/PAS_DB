﻿CREATE TABLE [dbo].[CommonWorkOrderTearDownAudit] (
    [CommonWorkOrderTearDownAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CommonWorkOrderTearDownId]      BIGINT         NULL,
    [CommonTeardownType]             VARCHAR (200)  NULL,
    [Memo]                           NVARCHAR (MAX) NULL,
    [TechnicianDate]                 DATETIME2 (7)  NULL,
    [InspectorDate]                  DATETIME2 (7)  NULL,
    [ReasonName]                     VARCHAR (200)  NULL,
    [InspectorName]                  VARCHAR (100)  NULL,
    [TechnicalName]                  VARCHAR (100)  NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  NOT NULL,
    [IsActive]                       BIT            NOT NULL,
    [IsDeleted]                      BIT            NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [IsSubWorkOrder]                 BIT            NULL,
    CONSTRAINT [PK_CommonWorkOrderTearDownAudit] PRIMARY KEY CLUSTERED ([CommonWorkOrderTearDownAuditId] ASC)
);


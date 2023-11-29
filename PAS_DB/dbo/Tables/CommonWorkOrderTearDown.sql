CREATE TABLE [dbo].[CommonWorkOrderTearDown] (
    [CommonWorkOrderTearDownId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CommonTeardownTypeId]      BIGINT         NULL,
    [WorkOrderId]               BIGINT         NOT NULL,
    [WorkFlowWorkOrderId]       BIGINT         NOT NULL,
    [WOPartNoId]                BIGINT         NOT NULL,
    [Memo]                      NVARCHAR (MAX) NULL,
    [ReasonId]                  BIGINT         NULL,
    [TechnicianId]              BIGINT         NULL,
    [TechnicianDate]            DATETIME2 (7)  NULL,
    [InspectorId]               BIGINT         NULL,
    [InspectorDate]             DATETIME2 (7)  NULL,
    [IsDocument]                BIT            DEFAULT ((0)) NOT NULL,
    [ReasonName]                VARCHAR (200)  NULL,
    [InspectorName]             VARCHAR (100)  NULL,
    [TechnicalName]             VARCHAR (100)  NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]           INT            DEFAULT ((1)) NOT NULL,
    [IsSubWorkOrder]            BIT            NULL,
    [SubWorkOrderId]            BIGINT         NULL,
    [SubWOPartNoId]             BIGINT         NULL,
    CONSTRAINT [PK_CommonWorkOrderTearDown] PRIMARY KEY CLUSTERED ([CommonWorkOrderTearDownId] ASC),
    CONSTRAINT [FK_CommonWorkOrderTearDown_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);








GO

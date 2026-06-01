CREATE TABLE [dbo].[WorksheetPart] (
    [WorksheetPartId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorksheetHeaderId]      BIGINT         NOT NULL,
    [ItemNo]                 VARCHAR (10)   NULL,
    [SignedBy]               VARCHAR (100)  NULL,
    [DefectDescription]      VARCHAR (500)  NULL,
    [MaintenanceAction]      VARCHAR (2000) NULL,
    [MaintenanceTime]        VARCHAR (20)   NULL,
    [MechBy]                 BIGINT         NULL,
    [InspBy]                 BIGINT         NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [IsActive]               BIT            CONSTRAINT [DF_WorksheetPart_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF_WorksheetPart_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]              VARCHAR (256)  DEFAULT ('') NOT NULL,
    [UpdatedBy]              VARCHAR (256)  DEFAULT ('') NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_WorksheetPart_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_WorksheetPart_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [SignedById]             BIGINT         NULL,
    [MaintenanceTimeMinutes] INT            NULL,
    CONSTRAINT [PK_WorksheetPart] PRIMARY KEY CLUSTERED ([WorksheetPartId] ASC),
    CONSTRAINT [FK_WorksheetPart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorksheetPart_WorksheetHeader] FOREIGN KEY ([WorksheetHeaderId]) REFERENCES [dbo].[WorksheetHeader] ([WorksheetHeaderId]) ON DELETE CASCADE
);


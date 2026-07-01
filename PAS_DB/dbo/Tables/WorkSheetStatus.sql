CREATE TABLE [dbo].[WorkSheetStatus] (
    [WorkSheetStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Status]            VARCHAR (256) NOT NULL,
    [StatusCode]        NVARCHAR (50) NULL,
    [Description]       VARCHAR (MAX) NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [WorkSheetStatus_DC_CDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [WorkSheetStatus_DC_UDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [D_WorkSheetStatus_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [D_WorkSheetStatus_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkSheetStatus] PRIMARY KEY CLUSTERED ([WorkSheetStatusId] ASC),
    CONSTRAINT [Unique_WorkSheetStatus] UNIQUE NONCLUSTERED ([Status] ASC, [MasterCompanyId] ASC)
);


CREATE TABLE [dbo].[ApprovalTask] (
    [ApprovalTaskId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ApprovalTask_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ApprovalTask_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [ApprovalTasks_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [ApprovalTasks_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ApprovalTask] PRIMARY KEY CLUSTERED ([ApprovalTaskId] ASC)
);


CREATE TABLE [dbo].[TaskInstructionMasterAudit] (
    [TaskInstructionAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TaskInstructionId]      BIGINT         NOT NULL,
    [Title]                  VARCHAR (8000) NULL,
    [Description]            VARCHAR (MAX)  NULL,
    [TaskId]                 BIGINT         NOT NULL,
    [SequenceNumber]         INT            NULL,
    [ParentId]               BIGINT         NULL,
    [IsParent]               BIT            NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (100)  NOT NULL,
    [UpdatedBy]              VARCHAR (100)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_TaskInstructionMasterAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_TaskInstructionMasterAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [DF__TaskInstructionMasterAudit__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF__TaskInstructionMasterAudit__IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsDefaultInstruction]   BIT            NULL,
    [IsParentInstruction]    BIT            NULL,
    CONSTRAINT [PK_TaskInstructionMasterAudit] PRIMARY KEY CLUSTERED ([TaskInstructionAuditId] ASC)
);




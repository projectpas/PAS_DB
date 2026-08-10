CREATE TABLE [dbo].[TaskInstructionMaster] (
    [TaskInstructionId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [Title]                VARCHAR (8000) NULL,
    [Description]          VARCHAR (MAX)  NULL,
    [TaskId]               BIGINT         NOT NULL,
    [SequenceNumber]       INT            NULL,
    [ParentId]             BIGINT         NULL,
    [IsParent]             BIT            NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (100)  NOT NULL,
    [UpdatedBy]            VARCHAR (100)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [DF_TaskInstructionMaster_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [DF_TaskInstructionMaster_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [DF__TaskInstructionMaster__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [DF__TaskInstructionMaster__IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsDefaultInstruction] BIT            NULL,
    [IsParentInstruction]  BIT            NULL,
    CONSTRAINT [PK_TaskInstructionMaster] PRIMARY KEY CLUSTERED ([TaskInstructionId] ASC)
);




GO

CREATE TRIGGER [dbo].[Trg_TaskInstructionMasterAudit]
    ON [dbo].[TaskInstructionMaster]
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[TaskInstructionMasterAudit]
    (
        [TaskInstructionId], [Title], [Description], [TaskId], [SequenceNumber],
        [ParentId], [IsParent], [MasterCompanyId], [CreatedBy], [UpdatedBy],
        [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
        [IsDefaultInstruction], [IsParentInstruction]
    )
    SELECT
        i.[TaskInstructionId], i.[Title], i.[Description], i.[TaskId], i.[SequenceNumber],
        i.[ParentId], i.[IsParent], i.[MasterCompanyId], i.[CreatedBy], i.[UpdatedBy],
        i.[CreatedDate], i.[UpdatedDate], i.[IsActive], i.[IsDeleted],
        i.[IsDefaultInstruction], i.[IsParentInstruction]
    FROM inserted i

    UNION ALL

    SELECT
        d.[TaskInstructionId], d.[Title], d.[Description], d.[TaskId], d.[SequenceNumber],
        d.[ParentId], d.[IsParent], d.[MasterCompanyId], d.[CreatedBy], d.[UpdatedBy],
        d.[CreatedDate], GETUTCDATE(), d.[IsActive], CAST(1 AS BIT),
        d.[IsDefaultInstruction], d.[IsParentInstruction]
    FROM deleted d
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM inserted i
        WHERE i.[TaskInstructionId] = d.[TaskInstructionId]
    );
END;
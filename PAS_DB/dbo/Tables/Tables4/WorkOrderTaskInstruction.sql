CREATE TABLE [dbo].[WorkOrderTaskInstruction] (
    [WorkOrderTaskInstructionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderTaskId]            BIGINT         NULL,
    [ParentId]                   BIGINT         NULL,
    [IsParent]                   BIT            NULL,
    [InstructionTitle]           VARCHAR (8000) NULL,
    [SequenceNumber]             INT            NULL,
    [InstructionDetails]         VARCHAR (MAX)  NULL,
    [TechId]                     BIGINT         NULL,
    [TechName]                   VARCHAR (100)  NULL,
    [TechUpdatedDate]            DATETIME2 (7)  NULL,
    [InspectorId]                BIGINT         NULL,
    [InspectorName]              VARCHAR (100)  NULL,
    [InspectorUpdatedDate]       DATETIME2 (7)  NULL,
    [PrintInWO]                  BIT            NULL,
    [PrintInWOQ]                 BIT            NULL,
    [MasterCompanyId]            INT            NULL,
    [CreatedBy]                  VARCHAR (100)  NULL,
    [UpdatedBy]                  VARCHAR (100)  NULL,
    [CreatedDate]                DATETIME2 (7)  NULL,
    [UpdatedDate]                DATETIME2 (7)  NULL,
    [IsActive]                   BIT            NULL,
    [IsDeleted]                  BIT            NULL,
    [IsFromWorkFlow]             BIT            NULL,
    [InstructionListId]          VARCHAR (250)  NULL,
    [ParentSequenceNumber]       VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_WorkOrderTaskInstruction] PRIMARY KEY CLUSTERED ([WorkOrderTaskInstructionId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_WorkOrderTaskInstructionAudit] ON [dbo].[WorkOrderTaskInstruction]
   AFTER INSERT,UPDATE  
AS   
BEGIN  
 INSERT INTO [dbo].[WorkOrderTaskInstructionAudit]  
 SELECT [WorkOrderTaskInstructionId],[WorkOrderTaskId],[ParentId],[IsParent],[InstructionTitle], 
		[SequenceNumber],[InstructionDetails],[TechId],[TechName],[TechUpdatedDate],
		[InspectorId],[InspectorName],[InspectorUpdatedDate],[PrintInWO],[PrintInWOQ],
		[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
		[ParentSequenceNumber],[InstructionListId]
 FROM INSERTED  
 SET NOCOUNT ON;  
END
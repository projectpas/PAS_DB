/*************************************************************           
 ** File:   [FleetQuoteTaskInstruction.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Task Instructions
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteTaskInstruction] (
    [FleetQuoteTaskInstructionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [FleetQuoteTaskId]            BIGINT         NULL,
    [ParentId]                   BIGINT         NULL,
    [IsParent]                   BIT            NULL,
    [InstructionTitle]           VARCHAR (8000) NULL,
    [SequenceNumber]             INT            NULL,
    [InstructionDetails]         VARCHAR (MAX)  NULL,
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
    CONSTRAINT [PK_FleetQuoteTaskInstruction] PRIMARY KEY CLUSTERED ([FleetQuoteTaskInstructionId] ASC),
    CONSTRAINT [FK_FleetQuoteTaskInstruction_FleetQuoteTask] FOREIGN KEY ([FleetQuoteTaskId]) REFERENCES [dbo].[FleetQuoteTask] ([FleetQuoteTaskId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteTaskInstructionAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteTaskInstructionAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteTaskInstructionAudit]
   ON [dbo].[FleetQuoteTaskInstruction]
   AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteTaskInstructionAudit]
    SELECT [FleetQuoteTaskInstructionId],[FleetQuoteTaskId],[ParentId],[IsParent],[InstructionTitle],
           [SequenceNumber],[InstructionDetails],[PrintInWO],[PrintInWOQ],[MasterCompanyId],
           [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],
           [IsFromWorkFlow],[InstructionListId],[ParentSequenceNumber]
    FROM INSERTED;
    SET NOCOUNT ON;
END;

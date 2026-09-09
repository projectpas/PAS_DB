/*************************************************************           
 ** File:   [FleetQuoteTask.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Dynamic Tasks
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteTask] (
    [FleetQuoteTaskId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteDetailsId]       BIGINT          NOT NULL,
    [TaskId]                    BIGINT          NULL, -- NULLABLE: Support ad-hoc tasks created directly in quote
    [TaskName]                  VARCHAR (500)   NULL,
    [SequenceNumber]            VARCHAR (10)    NULL,
    [OpenDate]                  DATETIME2 (7)   NULL,
    [OpenBy]                    VARCHAR (100)   NULL,
    [StandardHours]             INT             NULL,
    [StandardMinute]            INT             NULL,
    [IsIncludeInPrint]          BIT             NULL,
    [HasInstruction]            BIT             NULL,
    [IsFromWorkFlow]            BIT             NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteTask_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteTask_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_FleetQuoteTask_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_FleetQuoteTask_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_FleetQuoteTask] PRIMARY KEY CLUSTERED ([FleetQuoteTaskId] ASC),
    CONSTRAINT [FK_FleetQuoteTask_FleetQuoteDetails] FOREIGN KEY ([FleetQuoteDetailsId]) REFERENCES [dbo].[FleetQuoteDetails] ([FleetQuoteDetailsId]),
    CONSTRAINT [FK_FleetQuoteTask_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteTaskAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteTaskAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteTaskAudit]
   ON [dbo].[FleetQuoteTask]
   AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteTaskAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;

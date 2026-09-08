/*************************************************************           
 ** File:   [FleetQuoteTaskAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Dynamic Tasks
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteTaskAudit] (
    [AuditFleetQuoteTaskId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteTaskId]          BIGINT          NOT NULL,
    [FleetQuoteDetailsId]       BIGINT          NOT NULL,
    [TaskId]                    BIGINT          NULL,
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
    [CreatedDate]               DATETIME2 (7)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             NOT NULL,
    [IsDeleted]                 BIT             NOT NULL,
    CONSTRAINT [PK_FleetQuoteTaskAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteTaskId] ASC)
);

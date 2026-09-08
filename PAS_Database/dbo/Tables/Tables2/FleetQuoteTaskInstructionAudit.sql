/*************************************************************           
 ** File:   [FleetQuoteTaskInstructionAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Task Instructions
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteTaskInstructionAudit] (
    [AuditFleetQuoteTaskInstructionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [FleetQuoteTaskInstructionId]      BIGINT         NOT NULL,
    [FleetQuoteTaskId]                 BIGINT         NULL,
    [ParentId]                         BIGINT         NULL,
    [IsParent]                         BIT            NULL,
    [InstructionTitle]                 VARCHAR (8000) NULL,
    [SequenceNumber]                   INT            NULL,
    [InstructionDetails]               VARCHAR (MAX)  NULL,
    [PrintInWO]                        BIT            NULL,
    [PrintInWOQ]                       BIT            NULL,
    [MasterCompanyId]                  INT            NULL,
    [CreatedBy]                        VARCHAR (100)  NULL,
    [UpdatedBy]                        VARCHAR (100)  NULL,
    [CreatedDate]                      DATETIME2 (7)  NULL,
    [UpdatedDate]                      DATETIME2 (7)  NULL,
    [IsActive]                         BIT            NULL,
    [IsDeleted]                        BIT            NULL,
    [IsFromWorkFlow]                   BIT            NULL,
    [InstructionListId]                VARCHAR (250)  NULL,
    [ParentSequenceNumber]             VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_FleetQuoteTaskInstructionAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteTaskInstructionId] ASC)
);

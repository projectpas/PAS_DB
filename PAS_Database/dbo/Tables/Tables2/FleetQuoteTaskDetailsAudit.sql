/*************************************************************           
 ** File:   [FleetQuoteTaskDetailsAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Task Details
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteTaskDetailsAudit] (
    [AuditFleetQuoteTaskDetailsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [FleetQuoteTaskDetailsId]      BIGINT        NULL,
    [FleetQuoteTaskId]             BIGINT        NOT NULL,
    [OpenDate]                     DATETIME2 (7) NULL,
    [OpenBy]                       VARCHAR (100) NULL,
    [TechId]                       BIGINT        NULL,
    [TechName]                     VARCHAR (100) NULL,
    [TechUpdatedDate]              DATETIME2 (7) NULL,
    [InspectorId]                  BIGINT        NULL,
    [InspectorName]                VARCHAR (100) NULL,
    [InspectorUpdatedDate]         DATETIME2 (7) NULL,
    [Descrepancy]                  NVARCHAR (MAX) NULL,
    [Resolution]                   NVARCHAR (MAX) NULL,
    [HasInstruction]               BIT           NULL,
    [MasterCompanyId]              INT           NULL,
    [CreatedBy]                    VARCHAR (100) NULL,
    [UpdatedBy]                    VARCHAR (100) NULL,
    [CreatedDate]                  DATETIME2 (7) NULL,
    [UpdatedDate]                  DATETIME2 (7) NULL,
    [IsActive]                     BIT           NULL,
    [IsDeleted]                    BIT           NULL,
    [PrintInWO]                    BIT           NULL,
    [PrintInWOQ]                   BIT           NULL,
    [IsPrintInspector]             BIT           NULL,
    [IsPrintTechnician]            BIT           NULL,
    [IsPrintAdmin]                 BIT           NULL,
    CONSTRAINT [PK_FleetQuoteTaskDetailsAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteTaskDetailsId] ASC)
);

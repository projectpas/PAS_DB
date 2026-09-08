/*************************************************************           
 ** File:   [FleetQuoteLaborHeaderAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Labor Header
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteLaborHeaderAudit] (
    [AuditFleetQuoteLaborHeaderId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [FleetQuoteLaborHeaderId]      BIGINT        NOT NULL,
    [FleetQuoteDetailsId]          BIGINT        NOT NULL,
    [DataEnteredBy]                BIGINT        NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) NOT NULL,
    [IsActive]                     BIT           NOT NULL,
    [IsDeleted]                    BIT           NOT NULL,
    [MarkupFixedPrice]             VARCHAR (15)  NULL,
    [HeaderMarkupId]               BIGINT        NULL,
    CONSTRAINT [PK_FleetQuoteLaborHeaderAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteLaborHeaderId] ASC)
);

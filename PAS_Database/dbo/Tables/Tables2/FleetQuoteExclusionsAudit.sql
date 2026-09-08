/*************************************************************           
 ** File:   [FleetQuoteExclusionsAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Exclusions
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteExclusionsAudit] (
    [AuditFleetQuoteExclusionsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteExclusionsId]      BIGINT          NOT NULL,
    [FleetQuoteDetailsId]         BIGINT          NOT NULL,
    [ItemMasterId]                BIGINT          NULL,
    [ExstimtPercentOccuranceId]   INT             NULL,
    [Memo]                        NVARCHAR (MAX)  NULL,
    [Quantity]                    DECIMAL (18, 6) NULL,
    [UnitCost]                    DECIMAL (18, 6) NULL,
    [ExtendedCost]                DECIMAL (18, 6) NULL,
    [MarkUpPercentageId]          BIGINT          NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   NOT NULL,
    [IsActive]                    BIT             NOT NULL,
    [IsDeleted]                   BIT             NOT NULL,
    [TaskId]                      BIGINT          NULL,
    [MarkupFixedPrice]            VARCHAR (15)    NULL,
    [HeaderMarkupId]              BIGINT          NULL,
    [BillingMethodId]             INT             NULL,
    [BillingRate]                 DECIMAL (18, 6) NULL,
    [BillingAmount]               DECIMAL (18, 6) NULL,
    [ConditionId]                 BIGINT          NULL,
    CONSTRAINT [PK_FleetQuoteExclusionsAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteExclusionsId] ASC)
);

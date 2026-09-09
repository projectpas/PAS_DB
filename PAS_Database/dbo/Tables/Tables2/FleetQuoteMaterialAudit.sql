/*************************************************************           
 ** File:   [FleetQuoteMaterialAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Material Items
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteMaterialAudit] (
    [AuditFleetQuoteMaterialId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteMaterialId]      BIGINT          NOT NULL,
    [FleetQuoteDetailsId]       BIGINT          NOT NULL,
    [ItemMasterId]              BIGINT          NOT NULL,
    [ConditionCodeId]           BIGINT          NOT NULL,
    [ItemClassificationId]      BIGINT          NOT NULL,
    [Quantity]                  DECIMAL (18, 6) NULL,
    [UnitOfMeasureId]           BIGINT          NOT NULL,
    [UnitCost]                  DECIMAL (18, 6) NULL,
    [ExtendedCost]              DECIMAL (18, 6) NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [IsDefered]                 BIT             NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             NOT NULL,
    [IsDeleted]                 BIT             NOT NULL,
    [MarkupPercentageId]        BIGINT          NULL,
    [TaskId]                    BIGINT          NOT NULL,
    [MarkupFixedPrice]          VARCHAR (15)    NULL,
    [BillingAmount]             DECIMAL (18, 6) NULL,
    [BillingRate]               DECIMAL (18, 6) NULL,
    [HeaderMarkupId]            BIGINT          NULL,
    [ProvisionId]               INT             NOT NULL,
    [MaterialMandatoriesId]     INT             NULL,
    [BillingMethodId]           INT             NULL,
    [TaskName]                  VARCHAR (100)   NULL,
    [PartNumber]                VARCHAR (50)    NULL,
    [PartDescription]           VARCHAR (500)   NULL,
    [Provision]                 VARCHAR (50)    NULL,
    [UomName]                   VARCHAR (100)   NULL,
    [Conditiontype]             VARCHAR (50)    NULL,
    [Stocktype]                 VARCHAR (50)    NULL,
    [BillingName]               VARCHAR (50)    NULL,
    [MarkUp]                    VARCHAR (50)    NULL,
    [IsFromWorkFlow]            BIT             NULL,
    CONSTRAINT [PK_FleetQuoteMaterialAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteMaterialId] ASC)
);

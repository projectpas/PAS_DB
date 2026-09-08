/*************************************************************           
 ** File:   [FleetQuoteSettingsAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Configuration Settings
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteSettingsAudit] (
    [AuditFleetQuoteSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [FleetQuoteSettingId]      BIGINT        NOT NULL,
    [WorkOrderTypeId]          BIGINT        NOT NULL,
    [Prefix]                   VARCHAR (10)  NOT NULL,
    [Sufix]                    VARCHAR (10)  NULL,
    [StartCode]                BIGINT        NOT NULL,
    [ValidDays]                INT           NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) NOT NULL,
    [IsActive]                 BIT           NOT NULL,
    [IsDeleted]                BIT           NOT NULL,
    [CurrentNumber]            BIGINT        NOT NULL,
    [IsApprovalRule]           BIT           NULL,
    [EffectiveDate]            DATETIME      NULL,
    [TearDownTypes]            VARCHAR (50)  NULL,
    [IsFlatRate]               BIT           NULL,
    [IsPrintCorrectiveAction]  BIT           NULL,
    CONSTRAINT [PK_FleetQuoteSettingsAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteSettingId] ASC)
);

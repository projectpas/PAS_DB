/*************************************************************
 ** File:   [FleetQuoteStatusAudit.sql]
 ** Author:   Kishor Makwana
 ** Description: This Table is used to store Audit history for FleetQuoteStatus
 ** Date:   09/10/2026
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    09/10/2026   Kishor Makwana	Created [PN-17698]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteStatusAudit] (
    [FleetQuoteStatusAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [FleetQuoteStatusId]      BIGINT         NOT NULL,
    [Description]             VARCHAR (50)   NOT NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  NOT NULL,
    [IsActive]                BIT            NOT NULL,
    [IsDeleted]               BIT            NOT NULL,
    CONSTRAINT [PK_FleetQuoteStatusAudit] PRIMARY KEY CLUSTERED ([FleetQuoteStatusAuditId] ASC)
);

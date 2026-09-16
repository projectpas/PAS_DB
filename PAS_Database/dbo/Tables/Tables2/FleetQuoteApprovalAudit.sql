/*************************************************************
 ** File:   [FleetQuoteApprovalAudit.sql]
 ** Author:  Kishor Makwana
 ** Description: This Table is used to store Audit history for
 **              FleetQuoteApproval (PN-17704's "Approval Process" tab).
 **              Column order MUST stay in sync with dbo.FleetQuoteApproval,
 **              since Trg_FleetQuoteApprovalAudit does INSERT ... SELECT *
 **              FROM INSERTED - same convention as FleetQuoteAudit.sql /
 **              Trg_FleetQuoteAudit.
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17704]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteApprovalAudit] (
    [AuditFleetQuoteApprovalId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteApprovalId]      BIGINT          NOT NULL,
    [FleetQuoteId]              BIGINT          NOT NULL,
    [FleetQuoteDetailsId]       BIGINT          NOT NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CustomerSentDate]          DATETIME2 (7)   NULL,
    [CustomerStatusId]          INT             NULL,
    [CustomerApprovedById]      BIGINT          NULL,
    [CustomerApprovedDate]      DATETIME2 (7)   NULL,
    [CustomerRejectedById]      BIGINT          NULL,
    [CustomerRejectedDate]      DATETIME2 (7)   NULL,
    [CustomerMemo]              NVARCHAR (MAX)  NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             NOT NULL,
    [IsDeleted]                 BIT             NOT NULL,
    CONSTRAINT [PK_FleetQuoteApprovalAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteApprovalId] ASC)
);

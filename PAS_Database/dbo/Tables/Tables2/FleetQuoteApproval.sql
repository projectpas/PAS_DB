/*************************************************************
 ** File:   [FleetQuoteApproval.sql]
 ** Author:  Kishor Makwana
 ** Description: Customer approval state for the Aircraft / Fleet Quote
 **              screen's "Approval Process" tab (PN-17704). One row per
 **              dbo.FleetQuoteDetails line (the same MPN line the "MPNs"
 **              tab grid shows - see dbo.USP_GetFleetQuoteMPNList) -
 **              FleetQuoteDetailsId is UNIQUE below so there is at most
 **              one approval record per MPN line, upserted in place as
 **              the customer approval moves through its two steps:
 **
 **              1) "Send for Customer Approval" - CustomerSentDate is set
 **                 and CustomerStatusId is set to ApprovalStatusEnum.
 **                 WaitingForApproval (4) (see approval-status.enum.ts).
 **              2) Recording the customer's outcome - CustomerStatusId is
 **                 changed to Approved (2) or Rejected (3), together with
 **                 the matching CustomerApprovedById/CustomerApprovedDate
 **                 or CustomerRejectedById/CustomerRejectedDate and an
 **                 optional CustomerMemo.
 **
 **              This is the "Customer approval only" scope confirmed for
 **              PN-17704 - unlike dbo.WorkOrderApproval (Work Order
 **              Quote's own Approval Process tab), there is no internal-
 **              approver flow/bypass logic here, and no e-mail is sent
 **              when "Send for Customer Approval" runs - Submit just
 **              persists the row (see USP_UpsertFleetQuoteApproval.sql).
 **
 **              CustomerApprovedById/CustomerRejectedById store a
 **              CustomerContact.ContactId (the same list the Fleet Quote
 **              header's own Cust Contact dropdown uses - see
 **              fleet-quote.component.ts#customerContactList) with no FK
 **              constraint, same precedent as dbo.FleetQuote.
 **              CustomerContactId (see FleetQuote.sql) - that table is
 **              outside this ticket's SSDT scope.
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17704]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteApproval] (
    [FleetQuoteApprovalId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteId]          BIGINT          NOT NULL,
    [FleetQuoteDetailsId]   BIGINT          NOT NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CustomerSentDate]      DATETIME2 (7)   NULL,
    [CustomerStatusId]      INT             NULL,
    [CustomerApprovedById]  BIGINT          NULL,
    [CustomerApprovedDate]  DATETIME2 (7)   NULL,
    [CustomerRejectedById]  BIGINT          NULL,
    [CustomerRejectedDate]  DATETIME2 (7)   NULL,
    [CustomerMemo]          NVARCHAR (MAX)  NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteApproval_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteApproval_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_FleetQuoteApproval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_FleetQuoteApproval_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_FleetQuoteApproval] PRIMARY KEY CLUSTERED ([FleetQuoteApprovalId] ASC),
    CONSTRAINT [UQ_FleetQuoteApproval_FleetQuoteDetailsId] UNIQUE ([FleetQuoteDetailsId]),
    CONSTRAINT [FK_FleetQuoteApproval_FleetQuote] FOREIGN KEY ([FleetQuoteId]) REFERENCES [dbo].[FleetQuote] ([FleetQuoteId]),
    CONSTRAINT [FK_FleetQuoteApproval_FleetQuoteDetails] FOREIGN KEY ([FleetQuoteDetailsId]) REFERENCES [dbo].[FleetQuoteDetails] ([FleetQuoteDetailsId]),
    CONSTRAINT [FK_FleetQuoteApproval_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

GO

/*************************************************************
 ** File:   [Trg_FleetQuoteApprovalAudit]
 ** Author:  Kishor Makwana
 ** Description: This Trigger is used to insert data into FleetQuoteApprovalAudit
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17704]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteApprovalAudit]
   ON [dbo].[FleetQuoteApproval]
   AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteApprovalAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;

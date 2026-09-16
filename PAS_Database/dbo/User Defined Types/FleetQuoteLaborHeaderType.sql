/*************************************************************
 ** File:   [FleetQuoteLaborHeaderType.sql]
 ** Author:  Kishor Makwana
 ** Description: Table-valued parameter type for the single
 **              dbo.FleetQuoteLaborHeader row passed to
 **              dbo.USP_CreateFleetQuoteLabor (Aircraft / Fleet Quote
 **              screen's "Labor" build-up tab, PN-17707). Mirrors
 **              dbo.FleetQuoteLaborHeader column-for-column (real
 **              production schema, confirmed 09/2026 - this table already
 **              exists in the database; it is not part of this ticket's
 **              SSDT scope). One header row per dbo.FleetQuoteDetails line,
 **              carrying dbo.FleetQuoteLabor's own markup fields
 **              (MarkupFixedPrice/HeaderMarkupId) - same
 **              header + detail split Work Order Quote uses for its own
 **              Labor tab (this.laborPayload.WorkOrderQuoteLaborHeader in
 **              work-order-quote.component.ts).
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17707]
 **************************************************************/
CREATE TYPE [dbo].[FleetQuoteLaborHeaderType] AS TABLE (
    [FleetQuoteLaborHeaderId] BIGINT        NOT NULL,
    [FleetQuoteDetailsId]     BIGINT        NOT NULL,
    [DataEnteredBy]           BIGINT        NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) NULL,
    [UpdatedDate]             DATETIME2 (7) NULL,
    [IsActive]                BIT           NULL,
    [IsDeleted]               BIT           NULL,
    [MarkupFixedPrice]        VARCHAR (15)  NULL,
    [HeaderMarkupId]          BIGINT        NULL
);

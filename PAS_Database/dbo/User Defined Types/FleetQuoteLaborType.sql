/*************************************************************
 ** File:   [FleetQuoteLaborType.sql]
 ** Author:  Kishor Makwana
 ** Description: Table-valued parameter type for the detail-line rows
 **              passed to dbo.USP_CreateFleetQuoteLabor (Aircraft / Fleet
 **              Quote screen's "Labor" build-up tab, PN-17707). Mirrors
 **              dbo.FleetQuoteLabor column-for-column (real production
 **              schema, confirmed 09/2026 - this table already exists in
 **              the database; it is not part of this ticket's SSDT
 **              scope). BillableId and BurdaenRatePercentageId (real DB
 **              spelling) have no dropdown/lookup source anywhere in Work
 **              Order Quote's own code either - both are plain
 **              number/text entry, matching WOQ's own behavior exactly.
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17707]
 **************************************************************/
CREATE TYPE [dbo].[FleetQuoteLaborType] AS TABLE (
    [FleetQuoteLaborId]       BIGINT          NOT NULL,
    [FleetQuoteLaborHeaderId] BIGINT          NOT NULL,
    [ExpertiseId]             SMALLINT        NOT NULL,
    [Hours]                   DECIMAL (10, 2) NOT NULL,
    [BillableId]              INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   NULL,
    [UpdatedDate]             DATETIME2 (7)   NULL,
    [IsActive]                BIT             NULL,
    [IsDeleted]               BIT             NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [DirectLaborOHCost]       DECIMAL (18, 6) NULL,
    [MarkupPercentageId]      BIGINT          NULL,
    [BurdenRateAmount]        DECIMAL (18, 6) NULL,
    [TotalCostPerHour]        DECIMAL (18, 6) NULL,
    [TotalCost]               DECIMAL (18, 6) NULL,
    [BillingRate]             DECIMAL (18, 6) NULL,
    [BillingAmount]           DECIMAL (18, 6) NULL,
    [BurdaenRatePercentageId] BIGINT          NULL,
    [BillingMethodId]         INT             NULL,
    [MasterCompanyId]         INT             NULL,
    [TaskName]                VARCHAR (100)   NULL,
    [Expertise]               VARCHAR (50)    NULL,
    [Billabletype]            VARCHAR (50)    NULL,
    [BurdaenRatePercentage]   VARCHAR (50)    NULL,
    [BillingName]             VARCHAR (50)    NULL,
    [MarkUp]                  VARCHAR (50)    NULL,
    [EmployeeId]              BIGINT          NULL
);

/*************************************************************
 ** File:   [FleetQuoteChargesType.sql]
 ** Author:  Kishor Makwana
 ** Description: Table-valued parameter type for the detail-line rows
 **              passed to dbo.USP_CreateFleetQuoteCharges (Aircraft /
 **              Fleet Quote screen's "Charges" build-up tab, PN-17707).
 **              Mirrors dbo.FleetQuoteCharges column-for-column (real
 **              production schema, confirmed 09/2026 - this table already
 **              exists in the database; it is not part of this ticket's
 **              SSDT scope). ChargesTypeId has no dropdown/lookup source
 **              anywhere in Work Order Quote's own code (its equivalent
 **              workflowChargeTypeId/chargesTypeId is a plain id too) -
 **              plain number entry, matching WOQ's own behavior exactly.
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17707]
 **************************************************************/
CREATE TYPE [dbo].[FleetQuoteChargesType] AS TABLE (
    [FleetQuoteChargesId] BIGINT          NOT NULL,
    [FleetQuoteDetailsId] BIGINT          NOT NULL,
    [ChargesTypeId]       BIGINT          NOT NULL,
    [VendorId]            BIGINT          NULL,
    [Quantity]            DECIMAL (18, 6) NULL,
    [MarkupPercentageId]  BIGINT          NULL,
    [Description]         VARCHAR (256)   NULL,
    [UnitCost]            DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]        DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   NULL,
    [UpdatedDate]         DATETIME2 (7)   NULL,
    [IsActive]            BIT             NULL,
    [IsDeleted]           BIT             NULL,
    [TaskId]              BIGINT          NOT NULL,
    [MarkupFixedPrice]    VARCHAR (15)    NULL,
    [BillingAmount]       DECIMAL (20, 2) NULL,
    [BillingRate]         DECIMAL (20, 2) NULL,
    [HeaderMarkupId]      BIGINT          NULL,
    [RefNum]              VARCHAR (20)    NULL,
    [BillingMethodId]     INT             NULL,
    [TaskName]            VARCHAR (100)   NULL,
    [ChargeType]          VARCHAR (50)    NULL,
    [GlAccountName]       VARCHAR (50)    NULL,
    [VendorName]          VARCHAR (50)    NULL,
    [BillingName]         VARCHAR (50)    NULL,
    [MarkUp]              VARCHAR (50)    NULL,
    [UOMId]               BIGINT          NULL
);

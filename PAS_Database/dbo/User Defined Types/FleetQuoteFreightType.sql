/*************************************************************
 ** File:   [FleetQuoteFreightType.sql]
 ** Author:  Kishor Makwana
 ** Description: Table-valued parameter type for the detail-line rows
 **              passed to dbo.USP_CreateFleetQuoteFreight (Aircraft /
 **              Fleet Quote screen's "Freight" build-up tab, PN-17707).
 **              Mirrors dbo.FleetQuoteFreight column-for-column (real
 **              production schema, confirmed 09/2026 - this table already
 **              exists in the database; it is not part of this ticket's
 **              SSDT scope).
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17707]
 **************************************************************/
CREATE TYPE [dbo].[FleetQuoteFreightType] AS TABLE (
    [FleetQuoteFreightId]  BIGINT          NOT NULL,
    [FleetQuoteDetailsId]  BIGINT          NOT NULL,
    [ShipViaId]            BIGINT          NOT NULL,
    [Weight]               VARCHAR (50)    NULL,
    [Memo]                 NVARCHAR (MAX)  NULL,
    [Amount]               DECIMAL (20, 3) NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   NULL,
    [UpdatedDate]          DATETIME2 (7)   NULL,
    [IsActive]             BIT             NULL,
    [IsDeleted]            BIT             NULL,
    [MarkupPercentageId]   BIGINT          NULL,
    [MarkupFixedPrice]     VARCHAR (15)    NULL,
    [TaskId]               BIGINT          NOT NULL,
    [HeaderMarkupId]       BIGINT          NULL,
    [BillingRate]          DECIMAL (20, 2) NULL,
    [BillingAmount]        DECIMAL (20, 2) NULL,
    [Length]               DECIMAL (10, 2) NULL,
    [Width]                DECIMAL (10, 2) NULL,
    [Height]               DECIMAL (10, 2) NULL,
    [UOMId]                BIGINT          NULL,
    [DimensionUOMId]       BIGINT          NULL,
    [CurrencyId]           INT             NULL,
    [BillingMethodId]      INT             NULL,
    [TaskName]             VARCHAR (100)   NULL,
    [Shipvia]              VARCHAR (50)    NULL,
    [UomName]              VARCHAR (50)    NULL,
    [DimensionUomName]     VARCHAR (50)    NULL,
    [Currency]             VARCHAR (50)    NULL,
    [BillingName]          VARCHAR (50)    NULL,
    [MarkUp]               VARCHAR (50)    NULL
);

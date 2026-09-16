/*************************************************************
 ** File:   [FleetQuoteMaterialType.sql]
 ** Author:  Kishor Makwana
 ** Description: Table-valued parameter type for the detail-line rows
 **              passed to dbo.USP_CreateFleetQuoteMaterial (Aircraft /
 **              Fleet Quote screen's "Material List" build-up tab,
 **              PN-17707). Mirrors dbo.FleetQuoteMaterial column-for-
 **              column (real production schema, confirmed 09/2026 - this
 **              table already exists in the database; it is not part of
 **              this ticket's SSDT scope). The denormalized display
 **              columns (TaskName, PartNumber, PartDescription, Provision,
 **              UomName, Conditiontype, Stocktype, BillingName, MarkUp)
 **              are resolved client-side from the selected dropdown's own
 **              label at the moment a row is added/edited - same
 **              convention Work Order Quote's own
 **              @tbl_WorkOrderQuoteMaterialType TVP uses (see
 **              WorkOrderRepository.CreateWorkOrderQuoteMaterial's
 **              woqMaterial DataTable) - dbo.USP_CreateFleetQuoteMaterial
 **              persists whatever text it is given rather than re-
 **              resolving it from the id.
 ** Date:   14/09/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    14/09/2026   Kishor Makwana	Created [PN-17707]
 **************************************************************/
CREATE TYPE [dbo].[FleetQuoteMaterialType] AS TABLE (
    [FleetQuoteMaterialId]  BIGINT          NOT NULL,
    [FleetQuoteDetailsId]   BIGINT          NOT NULL,
    [ItemMasterId]          BIGINT          NOT NULL,
    [ConditionCodeId]       BIGINT          NOT NULL,
    [ItemClassificationId]  BIGINT          NOT NULL,
    [Quantity]              DECIMAL (18, 6) NULL,
    [UnitOfMeasureId]       BIGINT          NOT NULL,
    [UnitCost]              DECIMAL (18, 6) NULL,
    [ExtendedCost]          DECIMAL (18, 6) NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [IsDefered]             BIT             NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   NULL,
    [UpdatedDate]           DATETIME2 (7)   NULL,
    [IsActive]              BIT             NULL,
    [IsDeleted]             BIT             NULL,
    [MarkupPercentageId]    BIGINT          NULL,
    [TaskId]                BIGINT          NOT NULL,
    [MarkupFixedPrice]      VARCHAR (15)    NULL,
    [BillingAmount]         DECIMAL (18, 6) NULL,
    [BillingRate]           DECIMAL (18, 6) NULL,
    [HeaderMarkupId]        BIGINT          NULL,
    [ProvisionId]           INT             NOT NULL,
    [MaterialMandatoriesId] INT             NULL,
    [BillingMethodId]       INT             NULL,
    [TaskName]              VARCHAR (100)   NULL,
    [PartNumber]            VARCHAR (50)    NULL,
    [PartDescription]       VARCHAR (500)   NULL,
    [Provision]             VARCHAR (50)    NULL,
    [UomName]                VARCHAR (100)   NULL,
    [Conditiontype]         VARCHAR (50)    NULL,
    [Stocktype]             VARCHAR (50)    NULL,
    [BillingName]           VARCHAR (50)    NULL,
    [MarkUp]                VARCHAR (50)    NULL,
    [IsFromWorkFlow]        BIT             NULL
);

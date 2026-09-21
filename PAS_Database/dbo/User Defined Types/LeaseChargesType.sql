CREATE TYPE [dbo].[LeaseChargesType] AS TABLE (
    [LeaseChargesId]   BIGINT          NULL,
    [LeaseStocklineId] BIGINT          NULL,
    [ReportedDate]     DATETIME        NULL,
    [ChargesTypeId]    BIGINT          NULL,
    [Description]      VARCHAR (256)   NULL,
    [UOMId]            BIGINT          NULL,
    [Quantity]         DECIMAL (18, 6) NULL,
    [UnitCost]         DECIMAL (18, 6) NULL,
    [ExtendedCost]     DECIMAL (18, 6) NULL,
    [VendorId]         BIGINT          NULL,
    [IsDeleted]        BIT             NULL);

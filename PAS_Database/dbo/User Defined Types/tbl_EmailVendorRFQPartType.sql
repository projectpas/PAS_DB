CREATE TYPE [dbo].[tbl_EmailVendorRFQPartType] AS TABLE (
    [PartNumber]   NVARCHAR (200)  NULL,
    [Description]  NVARCHAR (500)  NULL,
    [Condition]    NVARCHAR (100)  NULL,
    [Qty]          INT             NULL,
    [RequestedQty] INT             NULL,
    [Price]        DECIMAL (18, 2) NULL,
    [Notes]        NVARCHAR (MAX)  NULL,
    [Manufacturer] NVARCHAR (500)  NULL);


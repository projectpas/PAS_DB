CREATE TYPE [dbo].[WorksheetPartTableType] AS TABLE (
    [WorksheetPartId]   BIGINT         NULL,
    [WorksheetHeaderId] BIGINT         NOT NULL,
    [ItemNo]            VARCHAR (10)   NULL,
    [SignedBy]          VARCHAR (100)  NULL,
    [DefectDescription] VARCHAR (500)  NULL,
    [MaintenanceAction] VARCHAR (2000) NULL,
    [MaintenanceTime]   VARCHAR (20)   NULL,
    [MechBy]            BIGINT         NULL,
    [InspBy]            BIGINT         NULL,
    [IsActive]          BIT            NULL,
    [IsDeleted]         BIT            NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL);


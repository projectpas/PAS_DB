CREATE TYPE [dbo].[EmailApprovalType] AS TABLE (
    [PartNumber]           VARCHAR (256)   NULL,
    [PartDescription]      VARCHAR (256)   NULL,
    [Qty]                  DECIMAL (18, 6) NULL,
    [TotalSales]           DECIMAL (18, 6) NULL,
    [RefrenceId]           BIGINT          NULL,
    [SubRefrenceId]        BIGINT          NULL,
    [ModuleId]             INT             NULL,
    [CustomerApprovedById] BIGINT          NULL,
    [CustomerId]           BIGINT          NULL,
    [InternalStatusId]     BIGINT          NULL,
    [IsActive]             BIT             NOT NULL,
    [IsDeleted]            BIT             NOT NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [ApprovalActionId]     BIGINT          NULL,
    [Email]                VARCHAR (256)   NOT NULL,
    [ContactId]            BIGINT          NULL);


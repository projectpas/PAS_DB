CREATE TABLE [dbo].[EmailApproval] (
    [EmailApprovalId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [PartNumber]           VARCHAR (256)   NULL,
    [PartDescription]      VARCHAR (256)   NULL,
    [Qty]                  INT             NULL,
    [TotalSales]           DECIMAL (18, 4) NULL,
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
    [ContactId]            BIGINT          NULL,
    CONSTRAINT [PK_EmailApproval] PRIMARY KEY CLUSTERED ([EmailApprovalId] ASC)
);


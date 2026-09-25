CREATE TYPE [dbo].[LeasePackagingSlipItemsType] AS TABLE (
    [LeasePickTicketId] BIGINT        NOT NULL,
    [LeaseStocklineId]  BIGINT        NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL);


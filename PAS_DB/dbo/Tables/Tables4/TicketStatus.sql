CREATE TABLE [dbo].[TicketStatus] (
    [TicketStatusId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (100) NULL,
    [Description]     VARCHAR (100) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsActive]        BIT           NULL,
    [IsDeleted]       BIT           NULL
);


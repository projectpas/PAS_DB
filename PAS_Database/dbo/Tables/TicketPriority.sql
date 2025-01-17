CREATE TABLE [dbo].[TicketPriority] (
    [PriorityId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100) NULL,
    [MasterCompanyId] INT           NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsActive]        BIT           NULL,
    [IsDeleted]       BIT           NULL
);


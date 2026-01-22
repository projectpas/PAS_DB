CREATE TABLE [dbo].[CustomerTicketResponse] (
    [TicketResponseId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerTicketId] BIGINT        NOT NULL,
    [ResponseById]     BIGINT        NOT NULL,
    [ResponseByName]   VARCHAR (200) NULL,
    [ResponseBody]     VARCHAR (MAX) NULL,
    [AttachmentId]     BIGINT        NULL,
    [MasterCompanyId]  INT           NULL,
    [CreatedBy]        VARCHAR (256) NULL,
    [UpdatedBy]        VARCHAR (256) NULL,
    [CreatedDate]      DATETIME2 (7) NULL,
    [UpdatedDate]      DATETIME2 (7) NULL,
    [IsActive]         BIT           NULL,
    [IsDeleted]        BIT           NULL,
    [StatusId]         INT           NOT NULL
);


CREATE TABLE [dbo].[ILSRFQDetail] (
    [ILSRFQDetailId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [ThirdPartyRFQId]  BIGINT         NOT NULL,
    [PriorityId]       INT            NULL,
    [Priority]         VARCHAR (50)   NULL,
    [RequestedQty]     INT            NULL,
    [QuoteWithinDays]  INT            NULL,
    [DeliverByDate]    DATETIME2 (7)  NULL,
    [PreparedBy]       VARCHAR (50)   NULL,
    [AttachmentId]     BIGINT         NULL,
    [DeliverToAddress] NVARCHAR (MAX) NULL,
    [BuyerComment]     NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NULL,
    [UpdatedBy]        VARCHAR (256)  NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [DF_ILSRFQDetail_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [DF_ILSRFQDetail_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [DF_ILSRFQDetail_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]         BIT            CONSTRAINT [DF_ILSRFQDetail_IsActive] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_ILSRFQDetail] PRIMARY KEY CLUSTERED ([ILSRFQDetailId] ASC),
    CONSTRAINT [FK_ILSRFQDetail_ThirdPartyRFQ] FOREIGN KEY ([ThirdPartyRFQId]) REFERENCES [dbo].[ThirdPartyRFQ] ([ThirdPartyRFQId])
);




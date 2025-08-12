CREATE TABLE [dbo].[QuoteSendReview] (
    [QuoteSendReviewId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [QuoteName]         VARCHAR (100) NULL,
    [Code]              VARCHAR (50)  NULL,
    [MasterCompanyId]   INT           NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_QuoteSendReview_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_QuoteSendReview_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [DF_QuoteSendReview_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [DF_QuoteSendReview_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_QuoteSendReview] PRIMARY KEY CLUSTERED ([QuoteSendReviewId] ASC)
);


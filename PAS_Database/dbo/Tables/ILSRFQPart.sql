CREATE TABLE [dbo].[ILSRFQPart] (
    [ILSRFQPartId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [ILSRFQDetailId]  BIGINT        NULL,
    [PartNumber]      VARCHAR (70)  NULL,
    [AltPartNumber]   VARCHAR (70)  NULL,
    [Exchange]        VARCHAR (70)  NULL,
    [Description]     VARCHAR (MAX) NULL,
    [Qty]             INT           NULL,
    [RequestedQty]    INT           NULL,
    [Condition]       VARCHAR (20)  NULL,
    [IsEmail]         BIT           NULL,
    [IsFax]           BIT           NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_ILSRFQPart_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_ILSRFQPart_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_ILSRFQPart_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]        BIT           CONSTRAINT [DF_ILSRFQPart_IsActive] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_ILSRFQPart] PRIMARY KEY CLUSTERED ([ILSRFQPartId] ASC),
    CONSTRAINT [FK_ILSRFQPart_ILSRFQDetail] FOREIGN KEY ([ILSRFQDetailId]) REFERENCES [dbo].[ILSRFQDetail] ([ILSRFQDetailId])
);




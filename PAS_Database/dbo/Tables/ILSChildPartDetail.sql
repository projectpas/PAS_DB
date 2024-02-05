CREATE TABLE [dbo].[ILSChildPartDetail] (
    [ILSChildPartId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [IntegrationMasterId] BIGINT        NULL,
    [AltPartNumber]       VARCHAR (200) NULL,
    [Qty]                 INT           NULL,
    [Cage]                VARCHAR (100) NULL,
    [Condition]           VARCHAR (50)  NULL,
    [Distance]            VARCHAR (50)  NULL,
    [ExchangeOption]      VARCHAR (50)  NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_ILSChildPartDetail_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_ILSChildPartDetail_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_ILSChildPartDetail_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]            BIT           CONSTRAINT [DF_ILSChildPartDetail_IsActive] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_ILSChildPartDetail] PRIMARY KEY CLUSTERED ([ILSChildPartId] ASC),
    CONSTRAINT [FK_ILSChildPartDetail_IntegrationMaster] FOREIGN KEY ([IntegrationMasterId]) REFERENCES [dbo].[IntegrationMaster] ([IntegrationMasterId])
);


CREATE TABLE [dbo].[POOnlyAddress] (
    [POOnlyAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderId] BIGINT        NOT NULL,
    [UserType]        INT           NOT NULL,
    [UserId]          BIGINT        NOT NULL,
    [SiteName]        VARCHAR (256) NULL,
    [AddressId]       BIGINT        NOT NULL,
    [IsPrimary]       BIT           NOT NULL,
    [IsShipping]      BIT           NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_POOnlyAddress] PRIMARY KEY CLUSTERED ([POOnlyAddressId] ASC)
);


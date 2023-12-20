CREATE TABLE [dbo].[POBillingShippingAddress] (
    [POBlShpId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [POAddressId]     BIGINT         NOT NULL,
    [UserType]        INT            NOT NULL,
    [AddressType]     INT            NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [AddressId]       BIGINT         NOT NULL,
    [ContactId]       BIGINT         NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [IsOnlyPOAddress] BIT            NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_POBillingShippingAddress] PRIMARY KEY CLUSTERED ([POBlShpId] ASC)
);


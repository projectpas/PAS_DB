CREATE TABLE [dbo].[InterCompanySetup] (
    [InterCompanySetupId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [AffiliateCode]             VARCHAR (50)  NULL,
    [AffiliateName]             VARCHAR (50)  NULL,
    [GLAccountToBeCredited]     BIGINT        NULL,
    [GLAccountToBeDebited]      BIGINT        NULL,
    [JournalType]               BIGINT        NULL,
    [DiscountFromCustomer]      VARCHAR (30)  NULL,
    [FXGainAndLossFromCustomer] VARCHAR (30)  NULL,
    [DiscountToCustomer]        VARCHAR (30)  NULL,
    [FXGainAndLossToCustomer]   VARCHAR (30)  NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NULL,
    [UpdatedDate]               DATETIME2 (7) NULL,
    [IsActive]                  BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([InterCompanySetupId] ASC)
);


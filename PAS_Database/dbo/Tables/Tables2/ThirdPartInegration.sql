CREATE TABLE [dbo].[ThirdPartInegration] (
    [ThirdPartInegrationId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]         BIGINT        NOT NULL,
    [CageCode]              VARCHAR (50)  NOT NULL,
    [APIURL]                VARCHAR (50)  NULL,
    [SecretKey]             VARCHAR (50)  NOT NULL,
    [AccessKey]             VARCHAR (50)  NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (50)  NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ThirdPartInegration_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (50)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_ThirdPartInegration_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_ThirdPartInegrationIsActi_59FA5E80] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_ThirdPartInegrationIsDele_5AEE82B9] DEFAULT ((0)) NOT NULL,
    [IntegrationIds]        BIGINT        NOT NULL,
    [IsEmail]               BIT           NULL,
    CONSTRAINT [PK_ThirdPartInegration] PRIMARY KEY CLUSTERED ([ThirdPartInegrationId] ASC)
);




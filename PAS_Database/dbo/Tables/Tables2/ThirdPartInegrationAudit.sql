CREATE TABLE [dbo].[ThirdPartInegrationAudit] (
    [ThirdPartInegrationAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ThirdPartInegrationId]      BIGINT        NULL,
    [LegalEntityId]              BIGINT        NULL,
    [CageCode]                   VARCHAR (50)  NULL,
    [APIURL]                     VARCHAR (50)  NULL,
    [SecretKey]                  VARCHAR (50)  NULL,
    [AccessKey]                  VARCHAR (50)  NULL,
    [MasterCompanyId]            INT           NULL,
    [CreatedBy]                  VARCHAR (50)  NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_ThirdPartInegrationAudit_CreatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedBy]                  VARCHAR (50)  NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_ThirdPartInegrationAudit_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [IsActive]                   BIT           CONSTRAINT [DF_ThirdPartInegrationAuditIsActi_59FA5E80] DEFAULT ((1)) NULL,
    [IsDeleted]                  BIT           CONSTRAINT [DF_ThirdPartInegrationAuditIsDele_5AEE82B9] DEFAULT ((0)) NULL,
    [IntegrationIds]             BIGINT        NOT NULL,
    [IsEmail]                    BIT           NULL,
    CONSTRAINT [PK_ThirdPartInegrationAudit] PRIMARY KEY CLUSTERED ([ThirdPartInegrationAuditId] ASC)
);




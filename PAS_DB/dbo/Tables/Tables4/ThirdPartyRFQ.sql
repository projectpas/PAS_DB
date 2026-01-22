CREATE TABLE [dbo].[ThirdPartyRFQ] (
    [ThirdPartyRFQId]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [RFQId]                  VARCHAR (50)  NULL,
    [PortalRFQId]            VARCHAR (50)  NULL,
    [Name]                   VARCHAR (100) NULL,
    [IntegrationRFQTypeId]   INT           NULL,
    [TypeName]               VARCHAR (50)  NULL,
    [IntegrationPortalId]    INT           NULL,
    [IntegrationPortal]      VARCHAR (50)  NULL,
    [IntegrationRFQStatusId] INT           NULL,
    [Status]                 VARCHAR (20)  NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NULL,
    [UpdatedBy]              VARCHAR (256) NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_ThirdPartyRFQ_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_ThirdPartyRFQ_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_ThirdPartyRFQ_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]               BIT           CONSTRAINT [DF_ThirdPartyRFQ_IsActive] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_ThirdPartyRFQ] PRIMARY KEY CLUSTERED ([ThirdPartyRFQId] ASC)
);


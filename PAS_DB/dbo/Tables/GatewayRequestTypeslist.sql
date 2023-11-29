CREATE TABLE [dbo].[GatewayRequestTypeslist] (
    [Id]                      INT          IDENTITY (1, 1) NOT NULL,
    [GatewayRequestTypesName] VARCHAR (50) NULL,
    [MasterCompanyId]         INT          NOT NULL,
    [CreatedBy]               VARCHAR (50) NOT NULL,
    [CreatedDate]             DATETIME     CONSTRAINT [DF_GatewayRequestTypeslist_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (50) NULL,
    [UpdatedDate]             DATETIME     CONSTRAINT [DF_GatewayRequestTypeslist_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [IsActive]                BIT          CONSTRAINT [DF_GatewayRequestTypeslist_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT          CONSTRAINT [DF_GatewayRequestTypeslist_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_GatewayRequestTypeslist] PRIMARY KEY CLUSTERED ([Id] ASC)
);


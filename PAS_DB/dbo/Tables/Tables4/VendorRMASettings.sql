CREATE TABLE [dbo].[VendorRMASettings] (
    [VendorRMASettingId]            BIGINT        IDENTITY (1, 1) NOT NULL,
    [EnforcePickTicketConfirmation] BIT           CONSTRAINT [DF_VendorRMASettings_EnforcePickTicketConfirmation] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NOT NULL,
    [CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_VendorRMASettings_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                     VARCHAR (256) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) CONSTRAINT [DF_VendorRMASettings_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT           CONSTRAINT [DF_VendorRMASettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT           CONSTRAINT [DF_VendorRMASettings_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorRMASettings] PRIMARY KEY CLUSTERED ([VendorRMASettingId] ASC)
);


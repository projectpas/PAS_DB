CREATE TABLE [dbo].[VendorStatusSettings] (
    [VendorStatusSettingsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Rating]                 VARCHAR (100) NULL,
    [OnTimeDelivery]         VARCHAR (100) NULL,
    [Description]            VARCHAR (256) NULL,
    [StatusId]               BIGINT        NULL,
    [IsAuditWarning]         BIT           NULL,
    [IsAuditRestriction]     BIT           NULL,
    [VarianceDays]           VARCHAR (100) NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_VendorStatusSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_VendorStatusSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF_VendorStatusSettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_VendorStatusSettings_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorStatusSettings] PRIMARY KEY CLUSTERED ([VendorStatusSettingsId] ASC)
);


GO
CREATE   Trigger [dbo].[trg_VendorStatusSettings]
ON [DBO].[VendorStatusSettings]

	AFTER INSERT,UPDATE

As  

Begin 


SET NOCOUNT ON

	INSERT INTO VendorStatusSettingsAudit ([VendorStatusSettingsId],[Rating],[OnTimeDelivery], [Description],[StatusId], [IsAuditWarning],[IsAuditRestriction],[VarianceDays],MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)

	SELECT [VendorStatusSettingsId],[Rating],[OnTimeDelivery], [Description],[StatusId], [IsAuditWarning],[IsAuditRestriction],[VarianceDays], MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted FROM INSERTED

	

End
CREATE TABLE [dbo].[VendorScoreCardSettings] (
    [VendorScoreCardSettingsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Rating]                    VARCHAR (100) NULL,
    [OnTimeDelivery]            VARCHAR (100) NULL,
    [Description]               VARCHAR (100) NULL,
    [StatusId]                  BIGINT        NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_VendorScoreCardSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_VendorScoreCardSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [DF_VendorScoreCardSettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [DF_VendorScoreCardSettings_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorScoreCardSettings] PRIMARY KEY CLUSTERED ([VendorScoreCardSettingsId] ASC)
);


GO
CREATE   Trigger [dbo].[trg_VendorScoreCardSettings]
ON [DBO].[VendorScoreCardSettings]

	AFTER INSERT,UPDATE

As  

Begin 


SET NOCOUNT ON

	INSERT INTO VendorScoreCardSettingsAudit ([VendorScoreCardSettingsId],[Rating],[OnTimeDelivery], [Description],[StatusId],MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)

	SELECT [VendorScoreCardSettingsId],[Rating],[OnTimeDelivery], [Description],[StatusId], MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted FROM INSERTED

	

End
CREATE TABLE [dbo].[VendorStatus] (
    [VendorStatusId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100) NOT NULL,
    [Memo]            VARCHAR (MAX) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_VendorStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_VendorStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_VendorStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_VendorStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorStatus] PRIMARY KEY CLUSTERED ([VendorStatusId] ASC)
);


GO
CREATE   Trigger [dbo].[trg_VendorStatus]
ON [DBO].[VendorStatus]

	AFTER INSERT,UPDATE

As  

Begin 


SET NOCOUNT ON

	INSERT INTO VendorStatusAudit ([VendorStatusId], [Description], [Memo],MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)

	SELECT [VendorStatusId], [Description], [Memo], MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted FROM INSERTED

	

End
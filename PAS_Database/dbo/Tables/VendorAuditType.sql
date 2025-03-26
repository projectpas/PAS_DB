CREATE TABLE [dbo].[VendorAuditType] (
    [VendorAuditTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorAuditType]   NVARCHAR (200) NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_VendorAuditType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_VendorAuditType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF_VendorAuditType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_VendorAuditType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorAuditType] PRIMARY KEY CLUSTERED ([VendorAuditTypeId] ASC)
);


GO
CREATE   Trigger [dbo].[trg_VendorAuditType]
ON [DBO].[VendorAuditType]

	AFTER INSERT,UPDATE

As  

Begin 


SET NOCOUNT ON

	INSERT INTO VendorAuditTypeAudit ([VendorAuditTypeId], [VendorAuditType], [Memo], MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)

	SELECT [VendorAuditTypeId], [VendorAuditType], [Memo], MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted FROM INSERTED

	

End
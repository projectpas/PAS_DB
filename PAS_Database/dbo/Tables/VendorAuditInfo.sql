CREATE TABLE [dbo].[VendorAuditInfo] (
    [VendorAuditInfoId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]          BIGINT        NOT NULL,
    [VendorOrderTypeId] BIGINT        NOT NULL,
    [VendorAuditTypeId] BIGINT        NOT NULL,
    [FrequencyDays]     INT           NULL,
    [LastAuditDate]     DATETIME2 (7) NULL,
    [NextAuditDate]     DATETIME2 (7) NULL,
    [Expired]           VARCHAR (50)  NULL,
    [AuditFindings]     VARCHAR (MAX) NULL,
    [ActionsTaken]      VARCHAR (MAX) NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorAuditInfo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorAuditInfo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [VendorAuditInfo_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [VendorAuditInfo_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]   INT           NULL,
    CONSTRAINT [PK_VendorAuditInfo] PRIMARY KEY CLUSTERED ([VendorAuditInfoId] ASC),
    CONSTRAINT [FK_VendorAuditInfo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE   Trigger [dbo].[trg_VendorAuditInfo]
ON [DBO].[VendorAuditInfo]
	AFTER INSERT,UPDATE
As  
Begin 
SET NOCOUNT ON
	
	INSERT INTO VendorAuditInfoAudit 
				([VendorAuditInfoId], [VendorId], [VendorOrderTypeId], [VendorAuditTypeId], [FrequencyDays], [LastAuditDate], 
				[NextAuditDate], [Expired], [AuditFindings], [ActionsTaken], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], 
				[IsActive], [IsDeleted],[MasterCompanyId])
	SELECT [VendorAuditInfoId], [VendorId], [VendorOrderTypeId], [VendorAuditTypeId], [FrequencyDays], [LastAuditDate], 
		   [NextAuditDate], [Expired], [AuditFindings], [ActionsTaken], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], 
		   [IsActive], [IsDeleted],[MasterCompanyId] FROM INSERTED

End
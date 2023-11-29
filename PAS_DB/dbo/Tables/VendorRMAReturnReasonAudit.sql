CREATE TABLE [dbo].[VendorRMAReturnReasonAudit] (
    [VendorRMAReturnReasonAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorRMAReturnReasonId]      BIGINT         NOT NULL,
    [Reason]                       VARCHAR (256)  NULL,
    [Memo]                         VARCHAR (1000) NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (50)   NOT NULL,
    [UpdatedBy]                    VARCHAR (50)   NOT NULL,
    [CreatedDate]                  DATETIME2 (7)  CONSTRAINT [DF_VendorRMAReturnReasonAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  CONSTRAINT [DF_VendorRMAReturnReasonAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                     BIT            CONSTRAINT [DF__VendorRMAReturnReasonAudit__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT            CONSTRAINT [DF__VendorRMAReturnReasonAudit__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorRMAReturnReasonAudit] PRIMARY KEY CLUSTERED ([VendorRMAReturnReasonAuditId] ASC)
);


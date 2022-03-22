CREATE TABLE [dbo].[ShippingContainerAudit] (
    [ShippingContainerAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShippingContainerId]      BIGINT         NOT NULL,
    [Description]              VARCHAR (50)   NOT NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DF_ShippingContainersAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  CONSTRAINT [DF_ShippingContainersAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT            CONSTRAINT [DF_ShippingContainersAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT            CONSTRAINT [DF_ShippingContainersAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ShippingContainersAudit] PRIMARY KEY CLUSTERED ([ShippingContainerAuditId] ASC)
);


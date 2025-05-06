CREATE TABLE [dbo].[RepairOrderTemplate] (
    [RepairOrderTemplateId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [RepairOrderTemplateNumber] VARCHAR (256)  NOT NULL,
    [ItemMasterId]              BIGINT         NOT NULL,
    [WorkPerformedId]           BIGINT         NULL,
    [CustomerId]                BIGINT         NULL,
    [PublicationRecordId]       BIGINT         NULL,
    [VendorId]                  BIGINT         NULL,
    [Instruction]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  NOT NULL,
    [IsActive]                  BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [ROT_RepairOrderTemplate] PRIMARY KEY CLUSTERED ([RepairOrderTemplateId] ASC),
    CONSTRAINT [FK_RepairOrderTemplate_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


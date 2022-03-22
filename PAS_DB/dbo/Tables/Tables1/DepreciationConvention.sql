CREATE TABLE [dbo].[DepreciationConvention] (
    [DepreciationConventionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ConventionCode]           VARCHAR (30)   NOT NULL,
    [Description]              VARCHAR (256)  NOT NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DepreciationConvention_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  CONSTRAINT [DepreciationConvention_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT            CONSTRAINT [DepreciationConvention_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT            CONSTRAINT [DepreciationConvention_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DepreciationConvention] PRIMARY KEY CLUSTERED ([DepreciationConventionId] ASC),
    CONSTRAINT [FK_DepreciationConvention_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_DepreciationConvention] UNIQUE NONCLUSTERED ([ConventionCode] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_DepreciationConventionAudit]

   ON  [dbo].[DepreciationConvention]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO DepreciationConventionAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
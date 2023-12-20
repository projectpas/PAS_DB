CREATE TABLE [dbo].[CustomerType] (
    [CustomerTypeId]   INT            IDENTITY (1, 1) NOT NULL,
    [Description]      NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [D_CT_CD] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [D_CT_UD] DEFAULT (sysdatetime()) NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [IsActive]         BIT            CONSTRAINT [D_CT_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [D_CT_Delete] DEFAULT ((0)) NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [CustomerTypeName] VARCHAR (256)  NOT NULL,
    [SequenceNo]       INT            NULL,
    CONSTRAINT [PK_CustomerType] PRIMARY KEY CLUSTERED ([CustomerTypeId] ASC),
    CONSTRAINT [FK_CustomerType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CustomerType] UNIQUE NONCLUSTERED ([CustomerTypeName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_CustomerTypeAudit]

   ON  [dbo].[CustomerType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO CustomerTypeAudit

SELECT CustomerTypeId,Description,MasterCompanyId,CreatedDate,UpdatedDate,CreatedBy,UpdatedBy,IsActive,IsDeleted,CustomerTypeName,Memo,SequenceNo FROM INSERTED

SET NOCOUNT ON;

END
CREATE TABLE [dbo].[Document] (
    [DocumentId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [DocumentCode]    VARCHAR (50)   NOT NULL,
    [Description]     VARCHAR (100)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Document_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Document_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_Document_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_Document_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Customer]        BIT            CONSTRAINT [DF__Document__Custom__3B4E1C33] DEFAULT ((0)) NOT NULL,
    [ItemMaster]      BIT            CONSTRAINT [DF__Document__ItemMa__3C42406C] DEFAULT ((0)) NOT NULL,
    [PO]              BIT            CONSTRAINT [DF__Document__PO__3D3664A5] DEFAULT ((0)) NOT NULL,
    [RO]              BIT            CONSTRAINT [DF__Document__RO__3E2A88DE] DEFAULT ((0)) NOT NULL,
    [SL]              BIT            CONSTRAINT [DF__Document__SL__3F1EAD17] DEFAULT ((0)) NOT NULL,
    [SO]              BIT            CONSTRAINT [DF__Document__SO__4012D150] DEFAULT ((0)) NOT NULL,
    [WO]              BIT            CONSTRAINT [DF__Document__WO__4106F589] DEFAULT ((0)) NOT NULL,
    [Vendor]          BIT            CONSTRAINT [DF__Document__Vendor__41FB19C2] DEFAULT ((0)) NOT NULL,
    [AttachmentId]    BIGINT         NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [DocumentTypeId]  BIGINT         NULL,
    CONSTRAINT [PK_Document] PRIMARY KEY CLUSTERED ([DocumentId] ASC),
    CONSTRAINT [UQ_DocumentCode_codes] UNIQUE NONCLUSTERED ([DocumentCode] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_DocumentAudit]

   ON  [dbo].[Document]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO DocumentAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
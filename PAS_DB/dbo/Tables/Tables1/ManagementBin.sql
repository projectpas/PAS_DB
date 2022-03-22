CREATE TABLE [dbo].[ManagementBin] (
    [ManagementBinId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [BinId]                 BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementBin_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementBin_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [ManagementBin_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [ManagementBin_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManagementBin] PRIMARY KEY CLUSTERED ([ManagementBinId] ASC),
    CONSTRAINT [FK_ManagementBin_Bin] FOREIGN KEY ([BinId]) REFERENCES [dbo].[Bin] ([BinId]),
    CONSTRAINT [FK_ManagementBin_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_ManagementBin_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_ManagementBinAudit]

   ON  [dbo].[ManagementBin]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ManagementBinAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
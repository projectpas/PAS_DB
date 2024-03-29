﻿CREATE TABLE [dbo].[ManagementShelf] (
    [ManagementShelfId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [ShelfId]               BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementShelf_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementShelf_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [ManagementShelf_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [ManagementShelf_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManagementShelf] PRIMARY KEY CLUSTERED ([ManagementShelfId] ASC),
    CONSTRAINT [FK_ManagementShelf_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ManagementShelf_Shelf] FOREIGN KEY ([ShelfId]) REFERENCES [dbo].[Shelf] ([ShelfId])
);


GO




CREATE TRIGGER [dbo].[Trg_ManagementShelfAudit]

   ON  [dbo].[ManagementShelf]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ManagementShelfAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
GO





Create TRIGGER [dbo].[Trg_ManagementShelfSaveMSDetails]

   ON  [dbo].[ManagementShelf]

   AFTER INSERT,UPDATE

AS

BEGIN


	SET NOCOUNT ON;
	DECLARE @ReferenceID bigint,@ModuleID int,@EntityMSID bigint,@MasterCompanyId bigint,@UpdatedBy VARCHAR(256),@MSDetailsId bigint

	set @ModuleID=60

	SELECT @ReferenceID=ShelfId,@EntityMSID=ManagementStructureId,@MasterCompanyId=MasterCompanyId,

	 @UpdatedBy=UpdatedBy

	FROM INSERTED

	EXEC dbo.[USP_SaveMSDetails] @ModuleID, @ReferenceID, @EntityMSID, @MasterCompanyId, @UpdatedBy, @MSDetailsId OUTPUT

	--IF UPDATE (ManagementSiteId) 
 --   BEGIN
 --       EXEC USP_UpdateMSDetails @ReferenceID, @EntityMSID, @UpdatedBy
 --   END 
	--else
	--begin

	--EXEC dbo.[USP_SaveMSDetails] @ModuleID, @ReferenceID, @EntityMSID, @MasterCompanyId, @UpdatedBy, @MSDetailsId OUTPUT

	--end

	


END
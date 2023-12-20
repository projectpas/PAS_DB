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
    CONSTRAINT [FK_ManagementBin_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO





Create TRIGGER [dbo].[Trg_ManagementBinSaveMSDetails]

   ON  [dbo].[ManagementBin]

   AFTER INSERT,UPDATE

AS

BEGIN


	SET NOCOUNT ON;
	DECLARE @ReferenceID bigint,@ModuleID int,@EntityMSID bigint,@MasterCompanyId bigint,@UpdatedBy VARCHAR(256),@MSDetailsId bigint

	set @ModuleID=58

	SELECT @ReferenceID=binid,@EntityMSID=ManagementStructureId,@MasterCompanyId=MasterCompanyId,

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
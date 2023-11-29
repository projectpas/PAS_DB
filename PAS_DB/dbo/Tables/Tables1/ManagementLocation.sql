CREATE TABLE [dbo].[ManagementLocation] (
    [ManagementLocationId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [LocationId]            BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementLocation_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementLocation_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [ManagementLocation_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [ManagementLocation_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManagementLocation] PRIMARY KEY CLUSTERED ([ManagementLocationId] ASC),
    CONSTRAINT [FK_ManagementLocation_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_ManagementLocation_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO




CREATE TRIGGER [dbo].[Trg_ManagementLocationAudit]

   ON  [dbo].[ManagementLocation]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ManagementLocationAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
GO





Create TRIGGER [dbo].[Trg_ManagementLocationSaveMSDetails]

   ON  [dbo].[ManagementLocation]

   AFTER INSERT,UPDATE

AS

BEGIN


	SET NOCOUNT ON;
	DECLARE @ReferenceID bigint,@ModuleID int,@EntityMSID bigint,@MasterCompanyId bigint,@UpdatedBy VARCHAR(256),@MSDetailsId bigint

	set @ModuleID=57

	SELECT @ReferenceID=locationid,@EntityMSID=ManagementStructureId,@MasterCompanyId=MasterCompanyId,

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
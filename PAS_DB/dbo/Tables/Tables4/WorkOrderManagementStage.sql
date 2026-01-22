CREATE TABLE [dbo].[WorkOrderManagementStage] (
    [ManagementStageId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [WorkOrderStageId]      BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_WorkOrderManagementStage_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_WorkOrderManagementStage_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_WorkOrderManagementStage_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_WorkOrderManagementStage_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderManagementStage] PRIMARY KEY CLUSTERED ([ManagementStageId] ASC),
    CONSTRAINT [FK_WorkOrderManagementStage_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderManagementStage_WorkOrderStage] FOREIGN KEY ([WorkOrderStageId]) REFERENCES [dbo].[WorkOrderStage] ([WorkOrderStageId])
);


GO





Create TRIGGER [dbo].[Trg_WorkOrderManagementStageSaveMSDetails]

   ON  [dbo].[WorkOrderManagementStage]

   AFTER INSERT,UPDATE

AS

BEGIN


	SET NOCOUNT ON;
	DECLARE @ReferenceID bigint,@ModuleID int,@EntityMSID bigint,@MasterCompanyId bigint,@UpdatedBy VARCHAR(256),@MSDetailsId bigint

	set @ModuleID=59

	SELECT @ReferenceID=WorkOrderStageId,@EntityMSID=ManagementStructureId,@MasterCompanyId=MasterCompanyId,

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
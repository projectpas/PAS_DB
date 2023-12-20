CREATE TABLE [dbo].[ItemMasterAircraftMapping] (
    [ItemMasterAircraftMappingId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]                BIGINT         NOT NULL,
    [AircraftTypeId]              INT            NOT NULL,
    [AircraftModelId]             BIGINT         NULL,
    [DashNumberId]                BIGINT         NULL,
    [PartNumber]                  VARCHAR (50)   NOT NULL,
    [DashNumber]                  VARCHAR (250)  NOT NULL,
    [AircraftType]                VARCHAR (250)  NOT NULL,
    [AircraftModel]               VARCHAR (250)  NOT NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  NULL,
    [UpdatedDate]                 DATETIME2 (7)  NULL,
    [IsActive]                    BIT            NOT NULL,
    [IsDeleted]                   BIT            NOT NULL,
    CONSTRAINT [PK_PNACMapping] PRIMARY KEY CLUSTERED ([ItemMasterAircraftMappingId] ASC),
    CONSTRAINT [FK_ItemMasterAircraftMapping_AircraftDashNumber] FOREIGN KEY ([DashNumberId]) REFERENCES [dbo].[AircraftDashNumber] ([DashNumberId]),
    CONSTRAINT [FK_ItemMasterAircraftMapping_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_ItemMasterAircraftMapping_AircraftType] FOREIGN KEY ([AircraftTypeId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_ItemMasterAircraftMapping_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMasterAircraftMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [IMAM_Unique] UNIQUE NONCLUSTERED ([ItemMasterId] ASC, [AircraftTypeId] ASC, [AircraftModelId] ASC, [DashNumberId] ASC, [MasterCompanyId] ASC)
);


GO


-----------------------------------------

CREATE TRIGGER [dbo].[Trg_ItemMasterAircraftMappingAudit]

   ON  [dbo].[ItemMasterAircraftMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[ItemMasterAircraftMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
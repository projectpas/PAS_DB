CREATE TABLE [dbo].[EntityStructureSetup] (
    [EntityStructureId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [Level1Id]              INT           NULL,
    [Level2Id]              INT           NULL,
    [Level3Id]              INT           NULL,
    [Level4Id]              INT           NULL,
    [Level5Id]              INT           NULL,
    [Level6Id]              INT           NULL,
    [Level7Id]              INT           NULL,
    [Level8Id]              INT           NULL,
    [Level9Id]              INT           NULL,
    [Level10Id]             INT           NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_EntityStructureSetup_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_EntityStructureSetup_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_EntityStructureSetup_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_EntityStructureSetup_IsDeleted] DEFAULT ((0)) NOT NULL,
    [OrganizationTagTypeId] BIGINT        NULL,
    CONSTRAINT [PK_EntityStructureSetup] PRIMARY KEY CLUSTERED ([EntityStructureId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_EntityStructureSetupAudit]
   ON  [dbo].[EntityStructureSetup]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[EntityStructureSetupAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
GO
CREATE TRIGGER [dbo].[Trg_UpdateEmployeeManagementStructureDetails]
   ON  [dbo].[EntityStructureSetup]
   AFTER UPDATE
AS 
BEGIN
	DECLARE @EntityStructureId INT;
	DECLARE @MasterCompanyId INT;
	DECLARE @MSLevel INT;
	DECLARE @LastMSName VARCHAR(200);
	DECLARE @Query VARCHAR(MAX);
    SELECT @EntityStructureId = INSERTED.EntityStructureId,@MasterCompanyId = INSERTED.MasterCompanyId
    FROM INSERTED;

	IF EXISTS(SELECT * FROM EmployeeManagementStructureDetails WHERE EntityMSID = @EntityStructureId AND MasterCompanyId = @MasterCompanyId)
	BEGIN
	IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
					BEGIN
					DROP TABLE #TempTable
					END

		CREATE TABLE #TempTable(LastMSName VARCHAR(MAX))

		UPDATE [dbo].[EmployeeManagementStructureDetails]
						SET [Level1Id] = EST.Level1Id,
							[Level1Name] = CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + CAST(MSL1.[Description] AS VARCHAR(MAX)),
							[Level2Id] = EST.Level2Id,
							[Level2Name] = CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + CAST(MSL2.[Description] AS VARCHAR(MAX)),
							[Level3Id] = EST.Level3Id,														
							[Level3Name] = CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + CAST(MSL3.[Description] AS VARCHAR(MAX)),
							[Level4Id] = EST.Level4Id,														
							[Level4Name] = CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + CAST(MSL4.[Description] AS VARCHAR(MAX)),
							[Level5Id] = EST.Level5Id,														
							[Level5Name] = CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + CAST(MSL5.[Description] AS VARCHAR(MAX)),
							[Level6Id] = EST.Level6Id,														
							[Level6Name] = CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + CAST(MSL6.[Description] AS VARCHAR(MAX)),
							[Level7Id] = EST.Level7Id,														
							[Level7Name] = CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + CAST(MSL7.[Description] AS VARCHAR(MAX)),
							[Level8Id] = EST.Level8Id,														
							[Level8Name] = CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + CAST(MSL8.[Description] AS VARCHAR(MAX)),
							[Level9Id] = EST.Level9Id,														
							[Level9Name] = CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + CAST(MSL9.[Description] AS VARCHAR(MAX)),
							[Level10Id] = EST.Level10Id,
							[Level10Name] = CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + CAST(MSL10.[Description] AS VARCHAR(MAX))
					FROM [dbo].EntityStructureSetup EST WITH(NOLOCK)
							 LEFT JOIN ManagementStructureLevel MSL1 WITH (NOLOCK) ON  EST.Level1Id = MSL1.ID
							 LEFT JOIN ManagementStructureLevel MSL2 WITH (NOLOCK) ON  EST.Level2Id = MSL2.ID
							 LEFT JOIN ManagementStructureLevel MSL3 WITH (NOLOCK) ON  EST.Level3Id = MSL3.ID
							 LEFT JOIN ManagementStructureLevel MSL4 WITH (NOLOCK) ON  EST.Level4Id = MSL4.ID
							 LEFT JOIN ManagementStructureLevel MSL5 WITH (NOLOCK) ON  EST.Level5Id = MSL5.ID
							 LEFT JOIN ManagementStructureLevel MSL6 WITH (NOLOCK) ON  EST.Level6Id = MSL6.ID
							 LEFT JOIN ManagementStructureLevel MSL7 WITH (NOLOCK) ON  EST.Level7Id = MSL7.ID
							 LEFT JOIN ManagementStructureLevel MSL8 WITH (NOLOCK) ON  EST.Level8Id = MSL8.ID
							 LEFT JOIN ManagementStructureLevel MSL9 WITH (NOLOCK) ON  EST.Level9Id = MSL9.ID
							 LEFT JOIN ManagementStructureLevel MSL10 WITH (NOLOCK) ON EST.Level10Id = MSL10.ID													   
					WHERE EST.EntityStructureId=@EntityStructureId;

					SELECT @MSLevel = MC.ManagementStructureLevel
					FROM [dbo].[MasterCompany] MC WITH(NOLOCK) 
					WHERE MC.MasterCompanyId = @MasterCompanyId

					SET @Query = N'INSERT INTO #TempTable (LastMSName) SELECT DISTINCT TOP 1 CAST ( Level' + CAST( + @MSLevel AS VARCHAR(20)) + 'Name AS VARCHAR(MAX)) FROM [dbo].[EmployeeManagementStructureDetails] MSD WITH(NOLOCK) 
					WHERE MSD.EntityMSID = CAST (' + CAST(@EntityStructureId AS VARCHAR(20)) + ' AS INT)'

					EXECUTE(@Query)

					UPDATE [dbo].[EmployeeManagementStructureDetails] 
						SET [LastMSLevel] = LastMSName,
							[AllMSlevels] = (SELECT AllMSlevels FROM DBO.udfGetAllEntityMSLevelString(@EntityStructureId))
					FROM #TempTable WHERE EntityMSID = @EntityStructureId

					IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
					BEGIN
					DROP TABLE #TempTable
					END
		
	END
	SET NOCOUNT ON;
END
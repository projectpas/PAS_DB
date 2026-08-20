CREATE TABLE [dbo].[SalesPersonActivityType] (
    [SalesPersonActivityTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                BIGINT        NOT NULL,
    [DropdownTypeId]            BIGINT        NOT NULL,
    [ActivityTypeId]            BIGINT        NOT NULL,
    [RevenuePercentageId]       BIGINT        NULL,
    [MarginPercentageId]        BIGINT        NULL,
    [EffectiveDate]             DATETIME2 (7) NOT NULL,
    [EntityStructureId]         BIGINT        NULL,
    [Level1]                    VARCHAR (256) NULL,
    [Level2]                    VARCHAR (256) NULL,
    [Level3]                    VARCHAR (256) NULL,
    [Level4]                    VARCHAR (256) NULL,
    [MasterCompanyId]           INT           CONSTRAINT [SalesPersonActivityType_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]                 VARCHAR (256) CONSTRAINT [SalesPersonActivityType_CreatedBy] DEFAULT ('admin') NOT NULL,
    [UpdatedBy]                 VARCHAR (256) CONSTRAINT [SalesPersonActivityType_UpdatedBy] DEFAULT ('admin') NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [SalesPersonActivityType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [SalesPersonActivityType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [SalesPersonActivityType_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [SalesPersonActivityType_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesPersonActivityType] PRIMARY KEY CLUSTERED ([SalesPersonActivityTypeId] ASC),
    CONSTRAINT [FK_SalesPersonActivityType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);






GO
CREATE   TRIGGER [dbo].[Trg_SalesPersonActivityTypeAudit]
   ON  [dbo].[SalesPersonActivityType]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO SalesPersonActivityTypeAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
GO
CREATE     TRIGGER [dbo].[trg_Audit_dbo_SalesPersonActivityType]
        ON [dbo].[SalesPersonActivityType]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;

            ;WITH 
            d AS (SELECT d.[SalesPersonActivityTypeId],d.[CustomerId],d.[DropdownTypeId],d.[ActivityTypeId],d.[RevenuePercentageId],d.[MarginPercentageId],d.[EffectiveDate],d.[EntityStructureId],d.[Level1],d.[Level2],d.[Level3],d.[Level4],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[SalesPersonActivityTypeId],i.[CustomerId],i.[DropdownTypeId],i.[ActivityTypeId],i.[RevenuePercentageId],i.[MarginPercentageId],i.[EffectiveDate],i.[EntityStructureId],i.[Level1],i.[Level2],i.[Level3],i.[Level4],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.SalesPersonActivityTypeId, d.SalesPersonActivityTypeId ) AS SalesPersonActivityTypeId,
					COALESCE(i.MasterCompanyId, d.MasterCompanyId) AS MasterCompanyId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.SalesPersonActivityTypeId IS NOT NULL AND d.SalesPersonActivityTypeId IS NOT NULL THEN 'U'
                        WHEN i.SalesPersonActivityTypeId IS NOT NULL AND d.SalesPersonActivityTypeId IS NULL     THEN 'I'
                        WHEN i.SalesPersonActivityTypeId IS NULL     AND d.SalesPersonActivityTypeId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.SalesPersonActivityTypeId, d.SalesPersonActivityTypeId) AS SalesPersonActivityTypeId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.SalesPersonActivityTypeId = d.SalesPersonActivityTypeId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.SalesPersonActivityTypeId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'SalesPersonActivityType'
                      AND ign.ColumnName = N'SalesPersonActivityTypeId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.SalesPersonActivityTypeId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'SalesPersonActivityType'
                      AND ign.ColumnName = N'SalesPersonActivityTypeId'
                )),
            merged AS (
                SELECT
                    COALESCE(n.PKJson, o.PKJson)                AS PKJson,
                    COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
					p.SalesPersonActivityTypeId,
					p.MasterCompanyId,
                    o.OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN oldv o
                    ON o.SalesPersonActivityTypeId = p.SalesPersonActivityTypeId
                LEFT JOIN newv n
                    ON n.SalesPersonActivityTypeId = p.SalesPersonActivityTypeId
                   AND n.ColumnName = o.ColumnName
                UNION ALL
                SELECT
                    n.PKJson,
                    n.ColumnName,
					p.SalesPersonActivityTypeId,
					p.MasterCompanyId,
                    NULL AS OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN newv n
                    ON n.SalesPersonActivityTypeId = p.SalesPersonActivityTypeId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.SalesPersonActivityTypeId = p.SalesPersonActivityTypeId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'SalesPersonActivityType' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
              CASE
				WHEN m.ColumnName = 'EntityStructureId' THEN CAST(MSLOld.Code AS NVARCHAR(250)) + ' - ' + MSLOld.[Description]
				WHEN m.ColumnName = 'RevenuePercentageId' THEN CAST(P_REV_OLD.PercentValue AS NVARCHAR(500))
				WHEN m.ColumnName = 'MarginPercentageId' THEN CAST(P_MAR_OLD.PercentValue AS NVARCHAR(500))
				WHEN m.ColumnName = 'DropdownTypeId' THEN
					CASE m.OldValue WHEN '1' THEN 'Primary Salesperson' WHEN '2' THEN 'Secondary Salesperson' WHEN '3' THEN 'Agent' ELSE 'CSR' END
				WHEN m.ColumnName = 'ActivityTypeId' THEN
					CASE m.OldValue WHEN '1' THEN 'MRO Activity' WHEN '2' THEN 'Brokering' ELSE 'Manafacturing' END
				ELSE m.OldValue
			END AS OldValue,
			CASE
				WHEN m.ColumnName = 'EntityStructureId' THEN CAST(MSLNew.Code AS NVARCHAR(250)) + ' - ' + MSLNew.[Description]
				WHEN m.ColumnName = 'RevenuePercentageId' THEN CAST(P_REV_NEW.PercentValue AS NVARCHAR(500))
				WHEN m.ColumnName = 'MarginPercentageId' THEN CAST(P_MAR_NEW.PercentValue AS NVARCHAR(500))
				WHEN m.ColumnName = 'DropdownTypeId' THEN
					CASE m.NewValue WHEN '1' THEN 'Primary Salesperson' WHEN '2' THEN 'Secondary Salesperson' WHEN '3' THEN 'Agent' ELSE 'CSR' END
				WHEN m.ColumnName = 'ActivityTypeId' THEN
					CASE m.NewValue WHEN '1' THEN 'MRO Activity' WHEN '2' THEN 'Brokering' ELSE 'Manafacturing' END
				ELSE m.NewValue
			END AS NewValue
		FROM merged m
			LEFT JOIN dbo.MasterCompany MC WITH (NOLOCK) ON MC.MasterCompanyId = m.MasterCompanyId
			LEFT JOIN dbo.EntityStructureSetup ESTOld WITH (NOLOCK) ON m.ColumnName = 'EntityStructureId' AND ESTOld.EntityStructureId = TRY_CAST(m.OldValue AS BIGINT)
			LEFT JOIN dbo.EntityStructureSetup ESTNew WITH (NOLOCK) ON m.ColumnName = 'EntityStructureId' AND ESTNew.EntityStructureId = TRY_CAST(m.NewValue AS BIGINT)
			CROSS APPLY (SELECT CASE MC.ManagementStructureLevel
				WHEN 1 THEN ESTOld.Level1Id WHEN 2 THEN ESTOld.Level2Id WHEN 3 THEN ESTOld.Level3Id WHEN 4 THEN ESTOld.Level4Id WHEN 5 THEN ESTOld.Level5Id
				WHEN 6 THEN ESTOld.Level6Id WHEN 7 THEN ESTOld.Level7Id WHEN 8 THEN ESTOld.Level8Id WHEN 9 THEN ESTOld.Level9Id WHEN 10 THEN ESTOld.Level10Id END AS LevelId) lvlOld
			CROSS APPLY (SELECT CASE MC.ManagementStructureLevel
				WHEN 1 THEN ESTNew.Level1Id WHEN 2 THEN ESTNew.Level2Id WHEN 3 THEN ESTNew.Level3Id WHEN 4 THEN ESTNew.Level4Id WHEN 5 THEN ESTNew.Level5Id
				WHEN 6 THEN ESTNew.Level6Id WHEN 7 THEN ESTNew.Level7Id WHEN 8 THEN ESTNew.Level8Id WHEN 9 THEN ESTNew.Level9Id WHEN 10 THEN ESTNew.Level10Id END AS LevelId) lvlNew
			LEFT JOIN dbo.ManagementStructureLevel MSLOld WITH (NOLOCK) ON MSLOld.ID = lvlOld.LevelId
			LEFT JOIN dbo.ManagementStructureLevel MSLNew WITH (NOLOCK) ON MSLNew.ID = lvlNew.LevelId
			LEFT JOIN [Percent] P_REV_OLD WITH (NOLOCK) ON P_REV_OLD.PercentId = TRY_CAST(m.OldValue AS BIGINT) AND m.ColumnName = 'RevenuePercentageId'
			LEFT JOIN [Percent] P_REV_NEW WITH (NOLOCK) ON P_REV_NEW.PercentId = TRY_CAST(m.NewValue AS BIGINT) AND m.ColumnName = 'RevenuePercentageId'
			LEFT JOIN [Percent] P_MAR_OLD WITH (NOLOCK) ON P_MAR_OLD.PercentId = TRY_CAST(m.OldValue AS BIGINT) AND m.ColumnName = 'MarginPercentageId'
			LEFT JOIN [Percent] P_MAR_NEW WITH (NOLOCK) ON P_MAR_NEW.PercentId = TRY_CAST(m.NewValue AS BIGINT) AND m.ColumnName = 'MarginPercentageId'
            WHERE
                m.ColumnName <> '<Enter your PrimaryKEY>' and (
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL));
        END;
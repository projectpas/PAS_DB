CREATE TABLE [dbo].[CoreLetter] (
    [CoreLetterId]      INT            IDENTITY (1, 1) NOT NULL,
    [HeaderName]        VARCHAR (100)  NOT NULL,
    [LetterDescription] NVARCHAR (MAX) NOT NULL,
    [LetterCode]        VARCHAR (50)   CONSTRAINT [DF_CoreLetter_LetterCode] DEFAULT ('') NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_CoreLetter_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_CoreLetter_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF_CoreLetter_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_CoreLetter_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CoreLetter] PRIMARY KEY CLUSTERED ([CoreLetterId] ASC)
);


GO


Create   TRIGGER [dbo].[Trg_CoreLetterAudit]

   ON  [dbo].[CoreLetter]

   AFTER INSERT,UPDATE

AS

BEGIN



	INSERT INTO [dbo].[CoreLetterAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END

GO
CREATE     TRIGGER [dbo].[trg_Audit_dbo_CoreLetter]
        ON [dbo].[CoreLetter]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[CoreLetterId],d.[HeaderName],d.[LetterDescription],d.[LetterCode],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[CoreLetterId],i.[HeaderName],i.[LetterDescription],i.[LetterCode],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.CoreLetterId, d.CoreLetterId ) AS CoreLetterId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.CoreLetterId IS NOT NULL AND d.CoreLetterId IS NOT NULL THEN 'U'
                        WHEN i.CoreLetterId IS NOT NULL AND d.CoreLetterId IS NULL     THEN 'I'
                        WHEN i.CoreLetterId IS NULL     AND d.CoreLetterId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.CoreLetterId, d.CoreLetterId) AS CoreLetterId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.CoreLetterId = d.CoreLetterId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.CoreLetterId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'CoreLetter'
                      AND ign.ColumnName = N'CoreLetterId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.CoreLetterId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'CoreLetter'
                      AND ign.ColumnName = N'CoreLetterId'
                )),
            merged AS (
                SELECT
                    COALESCE(n.PKJson, o.PKJson)                AS PKJson,
                    COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
                    o.OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN oldv o
                    ON o.CoreLetterId = p.CoreLetterId
                LEFT JOIN newv n
                    ON n.CoreLetterId = p.CoreLetterId
                   AND n.ColumnName = o.ColumnName
                UNION ALL
                SELECT
                    n.PKJson,
                    n.ColumnName,
                    NULL AS OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN newv n
                    ON n.CoreLetterId = p.CoreLetterId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.CoreLetterId = p.CoreLetterId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'CoreLetter' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL);
        END;

GO
CREATE     TRIGGER [dbo].[trg_CoreLetter_SetLetterCodeOnInsert]
	ON [dbo].[CoreLetter]
	AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE CL
	SET CL.LetterCode = LEFT(REPLACE(I.HeaderName, ' ', ''), 50)
	FROM [dbo].[CoreLetter] CL
	INNER JOIN INSERTED I ON CL.CoreLetterId = I.CoreLetterId
	WHERE ISNULL(I.LetterCode, '') = '';
END
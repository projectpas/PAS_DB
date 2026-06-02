/*********************             
 ** File:   [dbo].[usp_Get_CommonAuditLogHistory]        
 ** Author:   HEMANT SALIYA    
 ** Description: Get Data for Common Audit Report   
 ** Purpose:           
 ** Date:   07-NOV-2025        
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **********************             
  ** Change History             
 **********************             
 ** S NO		Date			Author				Change Description              
 ** --		--------		-------------		--------------------------------            
    1		07-NOV-2025		HEMANT SALIYA			Created  
    2       11-NOV-2025     AYUSHI PATEL            Mapped ModuleId to Module 
    3       12-NOV-2025     AYUSHI PATEL            Removed TableName, PKJson, ChangedBy, Actions from output; added UpdatedDate fallback to ChangedAt; excluded columns via IgnoreColumn.
    4       20-NOV-2025     AYUSHI PATEL            Converted UpdatedDate/CreatedDate to employee timezone.
    5       16-FEB-2026     DIVYESH KATHIRIYA       Set Table Name for SalesOrderQuote.
    6       25-FEB-2026     DIVYESH KATHIRIYA       Set New HistoryModule Table and Remove Table Name for SalesOrderQuote.
    7       27-FEB-2026     DIVYESH KATHIRIYA       Set @SubModuleId, @SubPK_Key, @SubPK_Value.
    8       10-MAR-2026     NAKUL CHANDIGRA         Add a condition of IgnoreColumn In '@sql = N';WITH S AS' to prevent Getting dublicate row (PN-15590)
    9       23-MAR-2026     NAKUL CHANDIGRA         Add a condition in the dynamic SQL to prevent getting duplicate rows for VendorContact Module.(PN-15772)
   10       29-MAR-2026     Amit Ghediya            get aircraft data.(PN-16154)
   11 	    15-MAY-2026	    DIVYESH KATHIRIYA       Combine Aircraft Hour and Minitues Like HH:MM. [PN-16398]
   12       02-JUN-2026     DIVYESH KATHIRIYA       Filter Aircraft Cycle History Noise From EngineName and metadata-only rows.[PN-16634]

 EXEC usp_Get_CommonAuditLogHistory @ModuleId=87,@PK_Key=N'AircraftCycleTimeMappingsId',@PK_Value=8,@EmployeeId=236, @SubModuleId=88, @SubPK_Key = '',@SubPK_Value=0
**********************/ 

CREATE PROC [dbo].[usp_Get_CommonAuditLogHistory]
    @ModuleId       BIGINT        = NULL,       -- e.g. '1 => Customer' / 'Vendor' (maps to TableName)
    @PK_Key         nvarchar(128) = NULL,       -- e.g. 'CustomerContactId'
    @PK_Value       nvarchar(128) = NULL,       -- e.g. '6678' (compared as NVARCHAR)
    @StartAt        datetime2(3)  = NULL,       -- inclusive
    @EndAt          datetime2(3)  = NULL,       -- exclusive
    @UseOld         bit           = 0,          -- 0 = pivot NewValue, 1 = pivot OldValue
    @SortDir        nvarchar(4)   = N'DESC',    -- ASC | DESC (by ChangedAt)
    @EmployeeId     BIGINT        = NULL,
    @SubModuleId    BIGINT        = NULL,       -- e.g. '1 => Customer' / 'Vendor' (maps to TableName)
    @SubPK_Key      nvarchar(128) = NULL,       -- e.g. 'ContactId'
    @SubPK_Value    nvarchar(128) = NULL        -- e.g. '14040'
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    BEGIN TRY
    
        DECLARE @sql nvarchar(MAX);
        DECLARE @cols nvarchar(MAX);
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
        DECLARE @Module VARCHAR(100);
        DECLARE @SubModule VARCHAR(100) = NULL;
        DECLARE @CustomerContactModule AS INT;    
        DECLARE @VendorContactModule AS INT;
		DECLARE @AircraftCycleTimeModule AS INT
        DECLARE @RefId BIGINT;
		DECLARE @DetailId VARCHAR(100);

        SELECT @RefId = ContactId
        FROM [dbo].[VendorContact]
        WHERE VendorContactId = TRY_CAST(@PK_Value AS BIGINT);

        -- Validate sort dir
        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';
    
        SET @Module = (SELECT [HistoryModuleName] FROM [dbo].[HistoryModule] WITH (NOLOCK) WHERE [HistoryModuleId] = @ModuleId);
        SET @SubModule = (SELECT [HistoryModuleName] FROM [dbo].[HistoryModule] WITH (NOLOCK) WHERE [HistoryModuleId] = @SubModuleId);

        SET @CustomerContactModule = (SELECT [HistoryModuleId] FROM [dbo].[HistoryModule] WITH(NOLOCK) WHERE [HistoryModuleName] = 'CustomerContact');
        SET @VendorContactModule = (SELECT [HistoryModuleId] FROM [dbo].[HistoryModule] WITH(NOLOCK) WHERE [HistoryModuleName] = 'VendorContact');
		SET @AircraftCycleTimeModule = (SELECT [HistoryModuleId] FROM [dbo].[HistoryModule] WITH(NOLOCK) WHERE [HistoryModuleName] = 'AircraftCycleTimeMappings');
       
        SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

---------------------------------------------------------------------------------
    -- Build dynamic column list from ColumnName in the filtered scope
    -- (ensures only relevant fields appear as pivoted columns)
-----------------------------------------------------------------------------------   
        
        IF (@ModuleId = @CustomerContactModule)
        BEGIN 
    
            SELECT @cols =
                STRING_AGG(QUOTENAME(ColumnName), ',')
            FROM (
                SELECT DISTINCT ColumnName
                FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                WHERE (
                        -- MAIN MODULE FILTER
                        (@Module IS NULL OR TableName = @Module
                            AND (
                                    @PK_Key IS NULL OR @PK_Value IS NULL
                                    OR TRY_CONVERT(nvarchar(128),
                                        JSON_VALUE(PKJson, CONCAT('$.', @PK_Key))) = @PK_Value
                                )
                        )
                        OR
                        -- SUB-MODULE FILTER (CustomerContact ? Contact)
                        (@Module IS NULL OR @Module = 'CustomerContact'
                            AND TableName = @SubModule
                            AND (
                                    @SubPK_Key   IS NOT NULL
                                AND @SubPK_Value IS NOT NULL
                                AND TRY_CONVERT(nvarchar(128),
                                    JSON_VALUE(PKJson, CONCAT('$.', @SubPK_Key))) = @SubPK_Value
                            )                
                        )
                    )
                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
                  AND ColumnName IS NOT NULL
                  AND ColumnName <> ''
                  AND LEN(ColumnName) <= 128         -- QUOTENAME limit
                  AND NOT EXISTS (            
                  SELECT 1
                  FROM dbo.IgnoreColumn ic WITH (NOLOCK)
                  WHERE ic.TableName = @Module
                    AND ic.ColumnName = AL.ColumnName
            )
            ) AS c;
        END
        ELSE IF (@ModuleId = @VendorContactModule)
        BEGIN 
            SELECT @cols =
                STRING_AGG(QUOTENAME(ColumnName), ',')
            FROM (
                SELECT DISTINCT ColumnName
                FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                WHERE ReferenceId = @RefId  

                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)

                  AND ColumnName IS NOT NULL
                  AND ColumnName <> ''
                  AND LEN(ColumnName) <= 128

                  AND NOT EXISTS (            
                      SELECT 1
                      FROM dbo.IgnoreColumn ic WITH (NOLOCK)
                      WHERE ic.TableName = AL.TableName  
                        AND ic.ColumnName = AL.ColumnName
                  )
            ) AS c;
        END
		ELSE IF (@ModuleId = @AircraftCycleTimeModule)
        BEGIN 
			SELECT @DetailId = STRING_AGG(CAST(AircraftEngineStartsMappingsId AS VARCHAR(50)), ',')
				FROM AircraftEngineStartsMappings
			WHERE AircraftCycleTimeMappingsId = @PK_Value;

            SELECT @cols =
                STRING_AGG(QUOTENAME(ColumnName), ',')
            FROM (
                SELECT DISTINCT ColumnName
                FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                 WHERE (@Module IS NULL OR TableName = @Module)
                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
				  AND TRY_CONVERT(BIGINT, JSON_VALUE(PKJson, '$.AircraftCycleTimeMappingsId')) = @PK_Value
                  AND ColumnName IS NOT NULL
                  AND ColumnName <> ''
                  AND LEN(ColumnName) <= 128 

				UNION ALL

				SELECT DISTINCT ColumnName
                FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                 WHERE (@SubModule IS NULL OR TableName = @SubModule)
                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
				  AND TRY_CONVERT(BIGINT, JSON_VALUE(PKJson, '$.aircraftenginestartsmappingsid')) IN(SELECT Item FROM DBO.SPLITSTRING(@DetailId,','))-- @PK_Value
                  AND ColumnName IS NOT NULL
                  AND ColumnName <> ''
                  AND LEN(ColumnName) <= 128
				  AND NOT EXISTS (            
					  SELECT 1
					  FROM dbo.IgnoreColumn ic WITH (NOLOCK)
					  WHERE ic.TableName = @SubModule
						AND ic.ColumnName = AL.ColumnName
				)
            ) AS c;
        END
        ELSE
        BEGIN
            SELECT @cols =
                STRING_AGG(QUOTENAME(ColumnName), ',')
            FROM (
                SELECT DISTINCT ColumnName
                FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                WHERE (@Module IS NULL OR TableName = @Module)
                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
                  AND (
                        @PK_Key IS NULL OR @PK_Value IS NULL
                        OR TRY_CONVERT(nvarchar(128), JSON_VALUE(PKJson, CONCAT('$.', @PK_Key))) = @PK_Value
                      )
				  --AND TRY_CONVERT(BIGINT, JSON_VALUE(PKJson, '$.aircraftcycletimemappingsid')) = @PK_Value
                  AND ColumnName IS NOT NULL
                  AND ColumnName <> ''
                  AND LEN(ColumnName) <= 128         -- QUOTENAME limit
                  AND NOT EXISTS (            
                  SELECT 1
                  FROM dbo.IgnoreColumn ic WITH (NOLOCK)
                  WHERE ic.TableName = @Module
                    AND ic.ColumnName = AL.ColumnName
            )
            ) AS c;
        END
		
        IF CHARINDEX('[UpdatedDate]', @cols) = 0
        SET @cols = @cols + ',[UpdatedDate]';

        IF CHARINDEX('[CreatedDate]', @cols) = 0
        SET @cols = @cols + ',[CreatedDate]';

        -- If nothing to pivot, return an empty-shaped set
        IF (@cols IS NULL OR @cols = '')
        BEGIN
            SELECT TOP (0)
                @Module AS TableName,
                @PK_Key AS PKJson,
                *
                FROM STRING_SPLIT(@cols,',')
            RETURN;
        END

        DECLARE @cols_out nvarchar(MAX);
        SELECT @cols_out =
            STRING_AGG(s.value, ',')
        FROM STRING_SPLIT(@cols, ',') AS s
        WHERE s.value NOT IN ('[UpdatedDate]', '[CreatedDate]');


        DECLARE @valExpr nvarchar(20) =
            CASE WHEN @UseOld = 1 THEN N'OldValue' ELSE N'NewValue' END;

    ----------------------------------------------------------------
    -- Dynamic pivot:
    --  - Deduplicate multiple rows for the same column at the same event
    --  - Pivot columns = each distinct ColumnName
    --  - Include a compact Actions string (e.g., 'I', 'U', 'D' or combination)
    ----------------------------------------------------------------
        IF (@ModuleId = @CustomerContactModule)
        BEGIN 
            SET @sql =N';WITH S AS
                        (
                            SELECT
                                AuditId,
                                TableName,
                                PKJson,
                                ColumnName,
                                [Action],
                                OldValue,
                                NewValue,
                                ChangedBy,
                                ChangedAt
                            FROM [dbo].[AuditLog] WITH (NOLOCK)
                            WHERE 1=1              
                              AND (
                                    -- MAIN MODULE FILTER
                                    (@Module  IS NULL OR TableName = @Module
                                        AND (
                                                @PK_Key IS NULL OR @PK_Value IS NULL
                                                OR TRY_CONVERT(nvarchar(128),
                                                   JSON_VALUE(PKJson, CONCAT(''$.'' , @PK_Key))) = @PK_Value
                                            )
                                    )

                                    OR

                                    -- SUB-MODULE FILTER (CustomerContact ? Contact)
                                    (@Module  IS NULL OR @Module = ''CustomerContact''
                                        AND TableName = ''' + ISNULL(@SubModule,'') + '''
                                        AND (
                                                @SubPK_Key   IS NOT NULL
                                            AND @SubPK_Value IS NOT NULL
                                            AND TRY_CONVERT(nvarchar(128),
                                                JSON_VALUE(PKJson, CONCAT(''$.'' , @SubPK_Key))) = @SubPK_Value
                                        )
                                    )
                                 )
                                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
              
                        ),'
        END
        ELSE IF (@ModuleId = @VendorContactModule)
        BEGIN 
            SET @sql = N';WITH S AS
            (
                SELECT
                    AuditId,
                    TableName,
                    PKJson,
                    ColumnName,
                    [Action],
                    OldValue,
                    NewValue,
                    ChangedBy,
                    ChangedAt,
                    ReferenceId   
                FROM [dbo].[AuditLog] WITH (NOLOCK)
                WHERE ReferenceId = @RefId  
                  AND TableName in (''VendorContact'',''Contact'')
                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
            ),'
        END
		ELSE IF (@ModuleId = @AircraftCycleTimeModule)
        BEGIN 
			SELECT @DetailId = STRING_AGG(CAST(AircraftEngineStartsMappingsId AS VARCHAR(50)), ',')
				FROM AircraftEngineStartsMappings
			WHERE AircraftCycleTimeMappingsId = @PK_Value;

			SET @sql = N';WITH RawS AS
						(
							SELECT
								AuditId,
								TableName,
								PKJson,
								ColumnName,
								[Action],
								OldValue,
								NewValue,
								ChangedBy,
								ChangedAt,
								ReferenceId   
							FROM [dbo].[AuditLog] WITH (NOLOCK)
							WHERE (@Module IS NULL OR TableName = @Module) 
							  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
							  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
							  AND TRY_CONVERT(INT, JSON_VALUE(PKJson, ''$.AircraftCycleTimeMappingsId'')) = @PK_Value

							UNION ALL

							SELECT
								AuditId,
								TableName,
								PKJson,
								ColumnName,
								[Action],
								OldValue,
								NewValue,
								ChangedBy,
								ChangedAt,
								ReferenceId   
							FROM [dbo].[AuditLog] WITH (NOLOCK)
							WHERE (@SubModule IS NULL OR TableName = @SubModule) 
							  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
							  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
							  AND TRY_CONVERT(INT, JSON_VALUE(PKJson, ''$.aircraftenginestartsmappingsid'')) IN (SELECT value FROM STRING_SPLIT(@DetailId, '',''))
						),
						FilterData AS
						(
							SELECT DISTINCT
								TableName,
								PKJson,
								ChangedAt,
								[Action]
							FROM RawS
							WHERE ColumnName NOT IN (''UpdatedBy'', ''UpdatedDate'', ''CreatedBy'', ''CreatedDate'')
							  AND NOT (
									TableName = @SubModule
									AND ColumnName = ''EngineName''
									AND (
										(OldValue IS NULL AND NewValue IS NULL)
										OR (OldValue IS NOT NULL AND NewValue IS NOT NULL AND OldValue = NewValue)
									)
							  )
						),
						S AS
						(
							SELECT AL.*
							FROM RawS AL
							INNER JOIN FilterData FD
								ON FD.TableName = AL.TableName
								AND FD.PKJson = AL.PKJson
								AND FD.ChangedAt = AL.ChangedAt
								AND FD.[Action] = AL.[Action]
						),';
        END
        ELSE
        BEGIN
            SET @sql = N';WITH S AS
                        (
                            SELECT
                                AuditId,
                                TableName,
                                PKJson,
                                ColumnName,
                                [Action],
                                OldValue,
                                NewValue,
                                ChangedBy,
                                ChangedAt
                            FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                            WHERE 1=1
                              AND (@Module  IS NULL OR TableName = @Module)
                              AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                              AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
                              AND (
                                    @PK_Key IS NULL OR @PK_Value IS NULL
                                    OR TRY_CONVERT(nvarchar(128), JSON_VALUE(PKJson, CONCAT(''$.'' , @PK_Key))) = @PK_Value
                                  )
                              AND NOT EXISTS ( SELECT 1 FROM dbo.IgnoreColumn ic WITH (NOLOCK) WHERE ic.TableName = @Module AND ic.ColumnName = AL.ColumnName )
                        ),'
        END   

		--select @sql
		--select 'first'

        IF (@ModuleId = @VendorContactModule)
        BEGIN
            SET @sql = N'
            WITH S AS
            (
                SELECT AuditId, TableName, PKJson, ColumnName, [Action],
                       OldValue, NewValue, ChangedBy, ChangedAt, ReferenceId
                FROM dbo.AuditLog WITH (NOLOCK)
                WHERE ReferenceId = @RefId
                    AND TableName IN (''VendorContact'',''Contact'')
                    AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                    AND (@EndAt IS NULL OR ChangedAt < @EndAt)
            ),

            S2 AS
            (
                SELECT AuditId, TableName, PKJson, ColumnName, [Action],
                       OldValue, NewValue, ChangedBy, ChangedAt, ReferenceId,
                       CAST(ChangedAt AS datetime2(0)) AS ChangedAtGrp
                FROM S
            ),

            Dedup AS
            (
                SELECT
                    ReferenceId,
                    ChangedAtGrp,
                    ChangedBy,
                    ColumnName,
                    [Action],
                    CONVERT(nvarchar(max), ' + @valExpr + N') AS ValToPivot,
                    ROW_NUMBER() OVER (
                        PARTITION BY ReferenceId, ChangedAtGrp, ColumnName
                        ORDER BY AuditId DESC
                    ) AS rn
                FROM S2
            ),

            FinalSource AS
            (
                SELECT
                    ReferenceId,
                    ChangedAtGrp,
                    ChangedBy,
                    ColumnName,
                    [Action],
                    ValToPivot
                FROM Dedup
                WHERE rn = 1
            ),

            Agg AS
            (
                SELECT
                    ReferenceId,
                    ChangedAtGrp,
                    MIN(ChangedBy) AS ChangedBy,
                    STRING_AGG([Action], '''') AS Actions
                FROM S2
                GROUP BY ReferenceId, ChangedAtGrp
            )

            SELECT
                p.ReferenceId,
                p.ChangedAtGrp,

                CASE 
                    WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0
                        THEN COALESCE(TRY_CAST(p.[UpdatedDate] AS datetime2(3)), p.ChangedAtGrp)

                    WHEN TRY_CAST(p.[UpdatedDate] AS datetime2(3)) IS NULL
                        OR TRY_CAST(p.[UpdatedDate] AS date) = ''0001-01-01''
                        THEN CAST(dbo.ConvertUTCtoLocal(p.ChangedAtGrp, @CurrntEmpTimeZoneDesc) AS datetime2(3))

                    ELSE CAST(dbo.ConvertUTCtoLocal(TRY_CAST(p.[UpdatedDate] AS datetime2(3)), @CurrntEmpTimeZoneDesc) AS datetime2(3))
                END AS UpdatedDate,

                CASE 
                    WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0
                        THEN TRY_CAST(p.[CreatedDate] AS datetime2(3))

                    WHEN TRY_CAST(p.[CreatedDate] AS datetime2(3)) IS NULL
                        OR TRY_CAST(p.[CreatedDate] AS date) = ''0001-01-01''
                        THEN NULL

                    ELSE CAST(dbo.ConvertUTCtoLocal(TRY_CAST(p.[CreatedDate] AS datetime2(3)), @CurrntEmpTimeZoneDesc) AS datetime2(3))
                END AS CreatedDate,

                a.Actions,
                a.ChangedBy'
    
                + CASE 
                    WHEN ISNULL(@cols_out,'') <> '' 
                    THEN ', ' + REPLACE(@cols_out, '],[', '], p.[')
                    ELSE '' 
                  END + N'

            FROM
            (
                SELECT ReferenceId, ChangedAtGrp, ColumnName, ValToPivot
                FROM FinalSource
            ) src

            PIVOT
            (
                MAX(ValToPivot)
                FOR ColumnName IN (' + @cols + N')
            ) p

            JOIN Agg a
                ON a.ReferenceId = p.ReferenceId
                AND a.ChangedAtGrp = p.ChangedAtGrp

            ORDER BY p.ChangedAtGrp ' + @SortDir + N';
            ';
        END
		ELSE IF (@ModuleId = @AircraftCycleTimeModule)
		BEGIN
			SET @sql += N'Dedup AS
            (
                SELECT
                    TableName, PKJson, ChangedAt, ChangedBy, ColumnName, [Action],
                    CONVERT(nvarchar(max), ' + @valExpr + N') AS ValToPivot,
                    ROW_NUMBER() OVER (
                        PARTITION BY TableName, PKJson, ChangedAt, ColumnName, [Action]
                        ORDER BY AuditId DESC
                    ) AS rn
                FROM S
            ),
            FinalSource AS
            (
                SELECT TableName, PKJson, ChangedAt, ChangedBy, ColumnName, [Action], ValToPivot
                FROM Dedup
                WHERE rn = 1
            ),
            Agg AS
            (
                SELECT
                    TableName,
                    PKJson,
                    ChangedAt,
                    MIN(ChangedBy) AS AnyChangedBy,               -- usually 1 user per event
                    [Action] AS Actions
                    --STRING_AGG(DISTINCT Action, '''') AS Actions   -- e.g. I/U/D compressed
                FROM S
                GROUP BY TableName, PKJson, ChangedAt, [Action]
            )
            SELECT
                p.TableName AS AuditTableName,
                p.PKJson AS AuditPKJson,
                CASE 
                    WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0
                            THEN COALESCE(p.[UpdatedDate], p.ChangedAt)
                    WHEN TRY_CAST(p.[UpdatedDate] AS datetime2(3)) IS NULL
                            OR TRY_CAST(p.[UpdatedDate] AS date) = ''0001-01-01''
                            THEN CAST(dbo.ConvertUTCtoLocal(p.ChangedAt, @CurrntEmpTimeZoneDesc) AS datetime2(3))
                    ELSE CAST(dbo.ConvertUTCtoLocal(TRY_CAST(p.[UpdatedDate] AS datetime2(3)), @CurrntEmpTimeZoneDesc) AS datetime2(3))
                END AS UpdatedDate,

                CASE 
                    WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0
                            THEN p.[CreatedDate]
                    WHEN TRY_CAST(p.[CreatedDate] AS datetime2(3)) IS NULL
                            OR TRY_CAST(p.[CreatedDate] AS date) = ''0001-01-01''
                            THEN NULL
                    ELSE CAST(dbo.ConvertUTCtoLocal(TRY_CAST(p.[CreatedDate] AS datetime2(3)), @CurrntEmpTimeZoneDesc) AS datetime2(3))
                END AS CreatedDate'
                + CASE WHEN ISNULL(@cols_out, N'') <> N'' THEN
                        N', ' + REPLACE(@cols_out, '],[', '], p.[')
                    ELSE N''
                    END
                + N'
            FROM
            (
                SELECT TableName, PKJson, ChangedAt, ChangedBy, ColumnName, ValToPivot
                FROM FinalSource
            ) AS src
            PIVOT
            (
                MAX(ValToPivot) FOR ColumnName IN (' + @cols + N')
            ) AS p
            JOIN Agg a
                ON a.TableName = p.TableName
                AND a.PKJson    = p.PKJson
                AND a.ChangedAt = p.ChangedAt
            ORDER BY p.ChangedAt ' + @SortDir + N', p.TableName, p.PKJson;';
		END
        ELSE
        BEGIN
            SET @sql += N'Dedup AS
            (
                -- If multiple rows for same (Table,PKJson,ChangedAt,ColumnName), take latest by AuditId
                SELECT
                    TableName, PKJson, ChangedAt, ChangedBy, ColumnName, [Action],
                    CONVERT(nvarchar(max), ' + @valExpr + N') AS ValToPivot,
                    ROW_NUMBER() OVER (
                        PARTITION BY TableName, PKJson, ChangedAt, ColumnName, [Action]
                        ORDER BY AuditId DESC
                    ) AS rn
                FROM S
            ),
            FinalSource AS
            (
                SELECT TableName, PKJson, ChangedAt, ChangedBy, ColumnName, [Action], ValToPivot
                FROM Dedup
                WHERE rn = 1
            ),
            Agg AS
            (
                SELECT
                    TableName,
                    PKJson,
                    ChangedAt,
                    MIN(ChangedBy) AS AnyChangedBy,               -- usually 1 user per event
                    [Action] AS Actions
                    --STRING_AGG(DISTINCT Action, '''') AS Actions   -- e.g. I/U/D compressed
                FROM S
                GROUP BY TableName, PKJson, ChangedAt, [Action]
            )
            SELECT
                CASE 
                    WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0
                            THEN COALESCE(p.[UpdatedDate], p.ChangedAt)
                    WHEN TRY_CAST(p.[UpdatedDate] AS datetime2(3)) IS NULL
                            OR TRY_CAST(p.[UpdatedDate] AS date) = ''0001-01-01''
                            THEN CAST(dbo.ConvertUTCtoLocal(p.ChangedAt, @CurrntEmpTimeZoneDesc) AS datetime2(3))
                    ELSE CAST(dbo.ConvertUTCtoLocal(TRY_CAST(p.[UpdatedDate] AS datetime2(3)), @CurrntEmpTimeZoneDesc) AS datetime2(3))
                END AS UpdatedDate,

                CASE 
                    WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0
                            THEN p.[CreatedDate]
                    WHEN TRY_CAST(p.[CreatedDate] AS datetime2(3)) IS NULL
                            OR TRY_CAST(p.[CreatedDate] AS date) = ''0001-01-01''
                            THEN NULL
                    ELSE CAST(dbo.ConvertUTCtoLocal(TRY_CAST(p.[CreatedDate] AS datetime2(3)), @CurrntEmpTimeZoneDesc) AS datetime2(3))
                END AS CreatedDate'
                + CASE WHEN ISNULL(@cols_out, N'') <> N'' THEN
                        N', ' + REPLACE(@cols_out, '],[', '], p.[')
                    ELSE N''
                    END
                + N'
            FROM
            (
                SELECT TableName, PKJson, ChangedAt, ChangedBy, ColumnName, ValToPivot
                FROM FinalSource
            ) AS src
            PIVOT
            (
                MAX(ValToPivot) FOR ColumnName IN (' + @cols + N')
            ) AS p
            JOIN Agg a
                ON a.TableName = p.TableName
                AND a.PKJson    = p.PKJson
                AND a.ChangedAt = p.ChangedAt
            ORDER BY p.ChangedAt ' + @SortDir + N', p.TableName, p.PKJson;';
        END 
		--SELECT @sql
    --EXEC sp_executesql
    --    @sql,
    --    N'@Module sysname, @StartAt datetime2(3), @EndAt datetime2(3), @PK_Key nvarchar(128), @PK_Value nvarchar(128), @CurrntEmpTimeZoneDesc varchar(100)',
    --      @Module=@Module, @StartAt=@StartAt,     @EndAt=@EndAt,       @PK_Key=@PK_Key,       @PK_Value=@PK_Value,     @CurrntEmpTimeZoneDesc = @CurrntEmpTimeZoneDesc;
    EXEC sp_executesql
        @sql,
        N'@Module sysname,@SubModule sysname,@DetailId nvarchar(128), @StartAt datetime2(3), @EndAt datetime2(3), @PK_Key nvarchar(128), @PK_Value nvarchar(128), @SubPK_Key nvarchar(128), @SubPK_Value nvarchar(128), @CurrntEmpTimeZoneDesc varchar(100) ,@RefId BIGINT',
          @Module=@Module,@SubModule=@SubModule,@DetailId = @DetailId, @StartAt=@StartAt,     @EndAt=@EndAt,       @PK_Key=@PK_Key,       @PK_Value=@PK_Value,     @SubPK_Key=@SubPK_Key,    @SubPK_Value=@SubPK_Value,  @CurrntEmpTimeZoneDesc = @CurrntEmpTimeZoneDesc ,@RefId = @RefId;
      
    END TRY    
  
    BEGIN CATCH  
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usp_Get_CommonAuditLogHistory]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Module, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@PK_Key, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@PK_Value, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@StartAt, '') AS varchar(100)) +  
            '@Parameter5 = ''' + CAST(ISNULL(@EndAt, '') AS varchar(100)) +  
            '@Parameter6 = ''' + CAST(ISNULL(@SortDir, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'  
  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH   
END

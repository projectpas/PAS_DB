/*************************************************************
 ** File:  [usprpt_GetTrainingReport]
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used to GetTrainingReport DATA.
 ** Purpose:
 ** Date:   26-Feb-2025

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author                Change Description
 ** --   --------     ----------------      --------------------------------
    1    26-Feb-2025   Bhargav Saliya       Created
    2    26-MAR-2025   Bhargav Saliya       Get Model Field Data
    3    27-MAR-2025   Bhargav Saliya       Add Employee and Training Type Filters
    4    15-MAR-2026   Sahdev Saliya        Added TrainingName, ProviderType, IsRecurring, DurationHours, DurationMinutes (PN-15933)
    5    15-APR-2026   Sahdev Saliya        Standards and performance improvements (PN-15933)
    6    15-APR-2026   Divyesh Kathiriya	Handle Multiple EmployeeId. [PN-15934]
	7    22-APR-2026   Sahdev Saliya        Added condion of IsDeleted for EmployeeTraining report List.(PN-16144)
    8    08/07/2026    Kishor Makwana       Added categoryType in select statement [PN-17166]
    9    08/07/2026    Kishor Makwana       Added categoryId and isRecurring filters [PN-17166]
    10   10-JUL-2026   Bhargav Saliya       Added Provider Type filter (Internal/External) [PN-17163]
    11   13-Jul-2026   Bhargav Saliya       Get start Date (PN-17217)
    12   16-Jul-2026   Bhargav Saliya       Get Duration with perfect formate (PN-17311)

************************************************************************/
CREATE      PROCEDURE [dbo].[usprpt_GetTrainingReport]
    @PageNumber      INT = 1,
    @PageSize        INT = NULL,
    @mastercompanyid INT,
    @xmlFilter       XML
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @Level1         VARCHAR(MAX) = NULL,
            @Level2         VARCHAR(MAX) = NULL,
            @Level3         VARCHAR(MAX) = NULL,
            @Level4         VARCHAR(MAX) = NULL,
            @Level5         VARCHAR(MAX) = NULL,
            @Level6         VARCHAR(MAX) = NULL,
            @Level7         VARCHAR(MAX) = NULL,
            @Level8         VARCHAR(MAX) = NULL,
            @Level9         VARCHAR(MAX) = NULL,
            @Level10        VARCHAR(MAX) = NULL,
            @EmployeeRaw    VARCHAR(100) = NULL,
            @TrainingTypeRaw VARCHAR(100) = NULL,
            @ModuleID       INT = 0,
            @CategoryIdRaw   VARCHAR(100) = NULL,
            @IsRecurringRaw     VARCHAR(10)  = NULL,
            @ProviderTypeRaw VARCHAR(50)  = NULL;

    BEGIN TRY

        SELECT @ModuleID = ManagementStructureModuleId
        FROM ManagementStructureModule WITH (NOLOCK)
        WHERE ModuleName = 'EmployeeGeneralInfo';

        SELECT
            @Level1          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level1'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level1          END,
            @Level2          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level2'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level2          END,
            @Level3          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level3'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level3          END,
            @Level4          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level4'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level4          END,
            @Level5          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level5'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level5          END,
            @Level6          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level6'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level6          END,
            @Level7          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level7'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level7          END,
            @Level8          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level8'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level8          END,
            @Level9          = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level9'         THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level9          END,
            @Level10         = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level10'        THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @Level10         END,
            @EmployeeRaw     = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Employee Name'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @EmployeeRaw     END,
            @TrainingTypeRaw = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Training Type'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @TrainingTypeRaw END,
            @CategoryIdRaw = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'categoryId'   THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @CategoryIdRaw END,
            @IsRecurringRaw   = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'isRecurring'  THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @IsRecurringRaw   END,
            @ProviderTypeRaw  = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'ProviderType' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @ProviderTypeRaw END

        FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby);

        -- Pre-compute level filter values once; avoids calling SPLITSTRING up to 20 times
        CREATE TABLE #Level1Ids  (Item INT);
        CREATE TABLE #Level2Ids  (Item INT);
        CREATE TABLE #Level3Ids  (Item INT);
        CREATE TABLE #Level4Ids  (Item INT);
        CREATE TABLE #Level5Ids  (Item INT);
        CREATE TABLE #Level6Ids  (Item INT);
        CREATE TABLE #Level7Ids  (Item INT);
        CREATE TABLE #Level8Ids  (Item INT);
        CREATE TABLE #Level9Ids  (Item INT);
        CREATE TABLE #Level10Ids (Item INT);
        CREATE TABLE #EmployeeIds (Item INT);
        CREATE TABLE #TrainingTypeIds (Item INT);
        CREATE TABLE #CategoryIds (Item INT);
        CREATE TABLE #IsRecurringIds (Item INT);
        

        IF NULLIF(@Level1,  '') IS NOT NULL  INSERT INTO #Level1Ids  SELECT Item FROM DBO.SPLITSTRING(@Level1,  ',');
        IF NULLIF(@Level2,  '') IS NOT NULL  INSERT INTO #Level2Ids  SELECT Item FROM DBO.SPLITSTRING(@Level2,  ',');
        IF NULLIF(@Level3,  '') IS NOT NULL  INSERT INTO #Level3Ids  SELECT Item FROM DBO.SPLITSTRING(@Level3,  ',');
        IF NULLIF(@Level4,  '') IS NOT NULL  INSERT INTO #Level4Ids  SELECT Item FROM DBO.SPLITSTRING(@Level4,  ',');
        IF NULLIF(@Level5,  '') IS NOT NULL  INSERT INTO #Level5Ids  SELECT Item FROM DBO.SPLITSTRING(@Level5,  ',');
        IF NULLIF(@Level6,  '') IS NOT NULL  INSERT INTO #Level6Ids  SELECT Item FROM DBO.SPLITSTRING(@Level6,  ',');
        IF NULLIF(@Level7,  '') IS NOT NULL  INSERT INTO #Level7Ids  SELECT Item FROM DBO.SPLITSTRING(@Level7,  ',');
        IF NULLIF(@Level8,  '') IS NOT NULL  INSERT INTO #Level8Ids  SELECT Item FROM DBO.SPLITSTRING(@Level8,  ',');
        IF NULLIF(@Level9,  '') IS NOT NULL  INSERT INTO #Level9Ids  SELECT Item FROM DBO.SPLITSTRING(@Level9,  ',');
        IF NULLIF(@Level10, '') IS NOT NULL  INSERT INTO #Level10Ids SELECT Item FROM DBO.SPLITSTRING(@Level10, ',');
        IF NULLIF(@EmployeeRaw, '') IS NOT NULL INSERT INTO #EmployeeIds(Item) SELECT DISTINCT TRY_CAST(Item AS INT)
            FROM DBO.SPLITSTRING(@EmployeeRaw, ',') WHERE TRY_CAST(Item AS INT) IS NOT NULL;
        IF NULLIF(@TrainingTypeRaw, '') IS NOT NULL INSERT INTO #TrainingTypeIds(Item) SELECT DISTINCT TRY_CAST(Item AS INT)
            FROM DBO.SPLITSTRING(@TrainingTypeRaw, ',') WHERE TRY_CAST(Item AS INT) IS NOT NULL;

        IF NULLIF(@CategoryIdRaw, '') IS NOT NULL INSERT INTO #CategoryIds(Item) SELECT DISTINCT TRY_CAST(Item AS INT) FROM DBO.SPLITSTRING(@CategoryIdRaw, ',')
            WHERE TRY_CAST(Item AS INT) IS NOT NULL AND TRY_CAST(Item AS INT) > 0;  
        
        IF NULLIF(@IsRecurringRaw, '') IS NOT NULL
    INSERT INTO #IsRecurringIds(Item)
    SELECT DISTINCT
        CASE WHEN TRY_CAST(Item AS INT) = 1 THEN 1   -- YES → 1
             WHEN TRY_CAST(Item AS INT) = 2 THEN 0   -- NO  → 0
        END
    FROM DBO.SPLITSTRING(@IsRecurringRaw, ',')
    WHERE TRY_CAST(Item AS INT) IN (1, 2); 

        

        IF ISNULL(@PageSize, 0) = 0
        BEGIN
            SELECT @PageSize = COUNT(DISTINCT E.EmployeeId)
            FROM DBO.Employee E WITH (NOLOCK)
                INNER JOIN dbo.EmployeeManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = E.EmployeeId
				INNER JOIN dbo.EmployeeTraining ET WITH (NOLOCK) ON E.EmployeeId = ET.EmployeeId AND ISNULL(ET.IsDeleted, 0) = 0

            WHERE E.mastercompanyid = @mastercompanyid
                AND E.IsActive  = 1
                AND E.IsDeleted = 0
                AND E.FirstName <> 'TBD'                
                AND (NOT EXISTS (SELECT 1 FROM #EmployeeIds)     OR E.EmployeeId IN (SELECT Item FROM #EmployeeIds))
                AND (NOT EXISTS (SELECT 1 FROM #TrainingTypeIds) OR ET.EmployeeTrainingTypeId IN (SELECT Item FROM #TrainingTypeIds))
                AND (NOT EXISTS (SELECT 1 FROM #Level1Ids)  OR MSD.[Level1Id]  IN (SELECT Item FROM #Level1Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level2Ids)  OR MSD.[Level2Id]  IN (SELECT Item FROM #Level2Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level3Ids)  OR MSD.[Level3Id]  IN (SELECT Item FROM #Level3Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level4Ids)  OR MSD.[Level4Id]  IN (SELECT Item FROM #Level4Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level5Ids)  OR MSD.[Level5Id]  IN (SELECT Item FROM #Level5Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level6Ids)  OR MSD.[Level6Id]  IN (SELECT Item FROM #Level6Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level7Ids)  OR MSD.[Level7Id]  IN (SELECT Item FROM #Level7Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level8Ids)  OR MSD.[Level8Id]  IN (SELECT Item FROM #Level8Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level9Ids)  OR MSD.[Level9Id]  IN (SELECT Item FROM #Level9Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level10Ids) OR MSD.[Level10Id] IN (SELECT Item FROM #Level10Ids));
        END

        ;WITH rptCTE AS (
            SELECT
                E.EmployeeId,
                E.FirstName AS firstName,
                E.LastName  AS lastName,
                J.Description AS title,
                ISNULL((
                    SELECT STRING_AGG(EE.[Description], ',')
                    FROM STRING_SPLIT(E.EmployeeExpIds, ',') AS ExpIds
                        LEFT JOIN DBO.EmployeeExpertise EE WITH (NOLOCK) ON EE.EmployeeExpertiseId = TRY_CAST(ExpIds.value AS INT)
                    WHERE NULLIF(ExpIds.value, '') IS NOT NULL
                ), '') AS expertise,
                E.Email       AS email,
                E.MobilePhone AS phone,
                ETP.TrainingType  AS trainingType,
                ET.Provider       AS provider,
                ET.IndustryCode   AS industryCode,
                FT.FrequencyName  AS frequency,
                ET.DurationHours,
                ET.DurationMinutes,
                CONVERT(VARCHAR(10), ET.ScheduleDate,   110) AS scheduleDate,
                CONVERT(VARCHAR(10), ET.CompletionDate, 110) AS completionDate,
                CONVERT(VARCHAR(10), ET.ExpirationDate, 110) AS expirationDate,
                --DATEDIFF(DAY, ET.ScheduleDate, ET.ExpirationDate) AS daysToExpiration,
                DATEDIFF(DAY, CAST(GETDATE() AS DATE), CAST(ET.ExpirationDate AS DATE)) AS DaysToExpiration,
                CASE WHEN ISNULL(EC.IsCertificationInForce, 0) = 1 THEN 'YES' ELSE 'NO' END AS inforce,
                AFT.Description AS aircraftType,
                STRING_AGG(A.ModelName, ', ') AS model,
                EC.CertifyingInstitution AS issuingEntity,
                EC.CertificationNumber   AS certNum,
                CONVERT(VARCHAR(10), ET.CreatedDate, 110) AS issueDate,
                TN.[Name]        AS trainingName,
                ET.ProviderType  AS providerType,
                CASE WHEN ISNULL(ET.IsRecurring, 0) = 1 THEN 'YES' ELSE 'NO' END AS isRecurring,
                UPPER(MSD.Level1Name)  AS level1,
                UPPER(MSD.Level2Name)  AS level2,
                UPPER(MSD.Level3Name)  AS level3,
                UPPER(MSD.Level4Name)  AS level4,
                UPPER(MSD.Level5Name)  AS level5,
                UPPER(MSD.Level6Name)  AS level6,
                UPPER(MSD.Level7Name)  AS level7,
                UPPER(MSD.Level8Name)  AS level8,
                UPPER(MSD.Level9Name)  AS level9,
                UPPER(MSD.Level10Name) AS level10,
                ET.CategoryType AS categoryType,
                ET.CategoryId  AS CategoryId,
                CONVERT(VARCHAR(10), ET.StartDate, 110) AS StartDate
            FROM DBO.Employee E WITH (NOLOCK)
                INNER JOIN dbo.EmployeeManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = E.EmployeeId
                LEFT JOIN dbo.JobTitle J WITH (NOLOCK) ON E.JobTitleId = J.JobTitleId
				INNER JOIN dbo.EmployeeTraining ET WITH (NOLOCK) ON E.EmployeeId = ET.EmployeeId AND ISNULL(ET.IsDeleted, 0) = 0
                LEFT JOIN dbo.EmployeeTrainingType ETP WITH (NOLOCK) ON ET.EmployeeTrainingTypeId = ETP.EmployeeTrainingTypeId
                LEFT JOIN dbo.FrequencyOfTraining FT WITH (NOLOCK) ON ET.FrequencyOfTrainingId = FT.FrequencyOfTrainingId
                LEFT JOIN dbo.AircraftType AFT WITH (NOLOCK) ON ET.AircraftManufacturerId = AFT.AircraftTypeId
                LEFT JOIN dbo.EmployeeCertification EC WITH (NOLOCK) ON E.EmployeeId = EC.EmployeeId
                LEFT JOIN dbo.EmployeeAircraftModelMapping EAMP WITH (NOLOCK) ON ET.EmployeeId = EAMP.EmployeeId
                LEFT JOIN dbo.AircraftModel A WITH (NOLOCK) ON A.AircraftModelId = EAMP.AircraftModelId
                LEFT JOIN dbo.TrainingName TN WITH (NOLOCK) ON ET.TrainingNameId = TN.TrainingNameId
            WHERE E.mastercompanyid = @mastercompanyid
                AND E.IsActive  = 1
                AND E.IsDeleted = 0
                AND E.FirstName <> 'TBD'                
                AND (NOT EXISTS (SELECT 1 FROM #EmployeeIds)     OR E.EmployeeId IN (SELECT Item FROM #EmployeeIds))
                AND (NOT EXISTS (SELECT 1 FROM #TrainingTypeIds) OR ET.EmployeeTrainingTypeId IN (SELECT Item FROM #TrainingTypeIds))
                AND (NOT EXISTS (SELECT 1 FROM #Level1Ids)  OR MSD.[Level1Id]  IN (SELECT Item FROM #Level1Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level2Ids)  OR MSD.[Level2Id]  IN (SELECT Item FROM #Level2Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level3Ids)  OR MSD.[Level3Id]  IN (SELECT Item FROM #Level3Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level4Ids)  OR MSD.[Level4Id]  IN (SELECT Item FROM #Level4Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level5Ids)  OR MSD.[Level5Id]  IN (SELECT Item FROM #Level5Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level6Ids)  OR MSD.[Level6Id]  IN (SELECT Item FROM #Level6Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level7Ids)  OR MSD.[Level7Id]  IN (SELECT Item FROM #Level7Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level8Ids)  OR MSD.[Level8Id]  IN (SELECT Item FROM #Level8Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level9Ids)  OR MSD.[Level9Id]  IN (SELECT Item FROM #Level9Ids))
                AND (NOT EXISTS (SELECT 1 FROM #Level10Ids) OR MSD.[Level10Id] IN (SELECT Item FROM #Level10Ids))
                AND (NOT EXISTS (SELECT 1 FROM #CategoryIds) OR ET.CategoryId  IN (SELECT Item FROM #CategoryIds))
                AND (NOT EXISTS (SELECT 1 FROM #IsRecurringIds) OR ISNULL(ET.IsRecurring, 0) IN (SELECT Item FROM #IsRecurringIds))
                AND (NULLIF(@ProviderTypeRaw, '') IS NULL OR UPPER(ET.ProviderType) = UPPER(@ProviderTypeRaw))
            GROUP BY
                E.EmployeeId, E.FirstName, E.LastName, J.Description,
                E.Email, E.MobilePhone, ETP.TrainingType, ET.Provider, ET.IndustryCode,
                FT.FrequencyName, ET.DurationHours, ET.DurationMinutes, ET.ScheduleDate, ET.CompletionDate,
                ET.ExpirationDate, EC.IsCertificationInForce, AFT.Description,
                EC.CertifyingInstitution, EC.CertificationNumber, ET.CreatedDate, TN.[Name], ET.ProviderType, ET.IsRecurring,
                MSD.Level1Name, MSD.Level2Name, MSD.Level3Name, MSD.Level4Name,
                MSD.Level5Name, MSD.Level6Name, MSD.Level7Name, MSD.Level8Name,
                MSD.Level9Name, MSD.Level10Name, E.EmployeeExpIds,ET.CategoryType,ET.CategoryId,ET.StartDate
        )
        SELECT
            COUNT(1) OVER () AS TotalRecordsCount,
            EmployeeId, firstName, lastName, title, expertise, email, phone, trainingType,
            provider, industryCode, frequency,
            CASE WHEN DurationHours IS NULL AND DurationMinutes IS NULL THEN NULL ELSE CONCAT(FORMAT(ISNULL(DurationHours, 0), '00'), ' : ', FORMAT(ISNULL(DurationMinutes, 0), '00')) END AS Duration,
            scheduleDate, completionDate, expirationDate,
            daysToExpiration, inforce, aircraftType, model, issuingEntity, certNum, issueDate,
            trainingName, providerType, isRecurring,
            level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,categoryType,StartDate
        FROM rptCTE
        ORDER BY EmployeeId DESC
        OFFSET ((@PageNumber - 1) * @PageSize) ROWS FETCH NEXT @PageSize ROWS ONLY
        OPTION (RECOMPILE);

    END TRY

    BEGIN CATCH

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[usprpt_GetTrainingReport]',
                @ProcedureParameters VARCHAR(3000) =
                    '@Parameter1 = ''' + CAST(ISNULL(@PageNumber,        '') AS VARCHAR(100)) + ''', ' +
                    '@Parameter2 = ''' + CAST(ISNULL(@PageSize,          '') AS VARCHAR(100)) + ''', ' +
                    '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid,   '') AS VARCHAR(100)) + ''', ' +
                    '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter,         '') AS VARCHAR(MAX))  + '''',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC Splogexception
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
            , 16, 1, @ErrorLogID);

        RETURN (1);

    END CATCH
END
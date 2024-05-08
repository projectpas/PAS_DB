/*************************************************************           
 ** File:   [USP_ManagementStructure_GetList]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used retrieve Entity Structure List    
 ** Purpose:         
 ** Date:   17/05/2022
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1    17/05/2022   Moin Bloch    Created

-- EXEC USP_ManagementStructure_GetList 1, 10, NULL, 1, N'', N'<?xml version="1.0" encoding="utf-16"?><ArrayOfFilter xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><Filter><FieldName>isDeleted</FieldName><FieldValue>false</FieldValue></Filter><Filter><FieldName>loginEmployeeId</FieldName><FieldValue>1</FieldValue></Filter><Filter><FieldName>masterCompanyId</FieldName><FieldValue>1</FieldValue></Filter></ArrayOfFilter>' 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_ManagementStructure_GetList]
	@PageNumber int = NULL,
	@PageSize int = NULL,
	@SortColumn varchar(50) = NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = NULL,
	@xmlFilter xml
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    DECLARE @RecordFrom int;
    DECLARE @Count int;
    DECLARE @IsActive bit;
    SET @RecordFrom = (@PageNumber - 1) * @PageSize;

    DECLARE @Level1Desc varchar(50) = NULL
    DECLARE @Level2Desc varchar(50) = NULL
    DECLARE @Level3Desc varchar(50) = NULL
    DECLARE @Level4Desc varchar(50) = NULL
    DECLARE @Level5Desc varchar(50) = NULL
    DECLARE @Level6Desc varchar(50) = NULL
    DECLARE @Level7Desc varchar(50) = NULL
    DECLARE @Level8Desc varchar(50) = NULL
    DECLARE @Level9Desc varchar(50) = NULL
    DECLARE @Level10Desc varchar(50) = NULL
    DECLARE @MasterCompanyId bigint = NULL
    DECLARE @CreatedBy varchar(50) = NULL
    DECLARE @CreatedDate datetime = NULL
    DECLARE @UpdatedBy varchar(50) = NULL
    DECLARE @UpdatedDate datetime = NULL
    DECLARE @IsDeleted bit = NULL

    SELECT
      @IsDeleted =
                  CASE
                    WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'isDeleted' THEN CONVERT(bit, filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)'))
                    ELSE @IsDeleted
                  END,
      @MasterCompanyId =
                        CASE
                          WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'masterCompanyId' THEN CONVERT(bigint, filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)'))
                          ELSE @MasterCompanyId
                        END,
      @Level1Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level1Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level1Desc
                   END,
      @Level2Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level2Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level2Desc
                   END,
      @Level3Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level3Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level3Desc
                   END,
      @Level4Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level4Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level4Desc
                   END,
      @Level5Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level5Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level5Desc
                   END,
      @Level6Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level6Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level6Desc
                   END,
      @Level7Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level7Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level7Desc
                   END,
      @Level8Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level8Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level8Desc
                   END,
      @Level9Desc =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level9Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                     ELSE @Level9Desc
                   END,
      @Level10Desc =
                    CASE
                      WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'level10Desc' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                      ELSE @Level10Desc
                    END

    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE (filterby)

    IF @IsDeleted IS NULL
    BEGIN
      SET @IsDeleted = 0
    END
    IF @SortColumn IS NULL
    BEGIN
      SET @SortColumn = UPPER('ESSetupId')
      SET @SortOrder = -1;
    END
    ELSE
    BEGIN
      SET @SortColumn = UPPER(@SortColumn)
    END

    ;WITH Result AS (SELECT COUNT(1) OVER () AS NumberOfItems,
      ES.[EntityStructureId],
      (ISNULL(ES.[Level1Id], 0)) 'Level1Id',
      --(ISNULL(ES.[Level1Desc], '')) 'Level1Desc',
	  '' AS 'Level1Desc',
      (ISNULL(ES.[Level2Id], 0)) 'Level2Id',
      --(ISNULL(ES.[Level2Desc], '')) 'Level2Desc',
	  '' AS 'Level2Desc',
      (ISNULL(ES.[Level3Id], 0)) 'Level3Id',
     -- (ISNULL(ES.[Level3Desc], '')) 'Level3Desc',
	 '' AS 'Level3Desc',
      (ISNULL(ES.[Level4Id], 0)) 'Level4Id',
     -- (ISNULL(ES.[Level4Desc], '')) 'Level4Desc',
	 '' AS 'Level4Desc',
      (ISNULL(ES.[Level5Id], 0)) 'Level5Id',
     -- (ISNULL(ES.[Level5Desc], '')) 'Level5Desc',
	 '' AS 'Level5Desc',
      (ISNULL(ES.[Level6Id], 0)) 'Level6Id',
     -- (ISNULL(ES.[Level6Desc], '')) 'Level6Desc',
	 '' AS 'Level6Desc',
      (ISNULL(ES.[Level7Id], 0)) 'Level7Id',
     -- (ISNULL(ES.[Level7Desc], '')) 'Level7Desc',
	 '' AS 'Level7Desc',
      (ISNULL(ES.[Level8Id], 0)) 'Level8Id',
     -- (ISNULL(ES.[Level8Desc], '')) 'Level8Desc',
	 '' AS 'Level8Desc',
      (ISNULL(ES.[Level9Id], 0)) 'Level9Id',
     -- (ISNULL(ES.[Level9Desc], '')) 'Level9Desc',
	 '' AS 'Level9Desc',
      (ISNULL(ES.[Level10Id], 0)) 'Level10Id',
     -- (ISNULL(ES.[Level10Desc], '')) 'Level10Desc',
	 '' AS 'Level10Desc',
      ES.[IsActive],
      ES.[IsDeleted],
      ES.[MasterCompanyId],
      0 AS IsSelected
    FROM [dbo].[EntityStructureSetup] ES WITH (NOLOCK)
    WHERE (ES.IsDeleted = @IsDeleted
    AND ES.MasterCompanyId = @MasterCompanyId)
    AND ((@GlobalFilter <> ''
    --AND ((ES.Level1Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level2Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level3Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level4Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level5Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level6Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level7Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level8Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level9Desc LIKE '%' + @GlobalFilter + '%')
    --OR (ES.Level10Desc LIKE '%' + @GlobalFilter + '%'))
	)
    OR (@GlobalFilter = ''
    --AND (ISNULL(@Level1Desc, '') = '' OR ES.Level1Desc LIKE '%' + @Level1Desc + '%')
    --AND (ISNULL(@Level2Desc, '') = '' OR ES.Level2Desc LIKE '%' + @Level2Desc + '%')
    --AND (ISNULL(@Level3Desc, '') = '' OR ES.Level3Desc LIKE '%' + @Level3Desc + '%')
    --AND (ISNULL(@Level4Desc, '') = '' OR ES.Level4Desc LIKE '%' + @Level4Desc + '%')
    --AND (ISNULL(@Level5Desc, '') = '' OR ES.Level5Desc LIKE '%' + @Level5Desc + '%')
    --AND (ISNULL(@Level6Desc, '') = '' OR ES.Level6Desc LIKE '%' + @Level6Desc + '%')
    --AND (ISNULL(@Level7Desc, '') = '' OR ES.Level7Desc LIKE '%' + @Level7Desc + '%')
    --AND (ISNULL(@Level8Desc, '') = '' OR ES.Level8Desc LIKE '%' + @Level8Desc + '%')
    --AND (ISNULL(@Level9Desc, '') = '' OR ES.Level9Desc LIKE '%' + @Level9Desc + '%')
    --AND (ISNULL(@Level10Desc, '') = '' OR ES.Level10Desc LIKE '%' + @Level10Desc + '%')
	)))

    SELECT * FROM Result ES

    ORDER BY CASE
      WHEN @SortOrder = 1 THEN CASE @SortColumn
          WHEN 'Level1Desc' THEN Level1Desc
          WHEN 'Level2Desc' THEN Level2Desc
          WHEN 'Level3Desc' THEN Level3Desc
          WHEN 'Level4Desc' THEN Level4Desc
          WHEN 'Level5Desc' THEN Level5Desc
          WHEN 'Level6Desc' THEN Level6Desc
          WHEN 'Level7Desc' THEN Level7Desc
          WHEN 'Level8Desc' THEN Level8Desc
          WHEN 'Level9Desc' THEN Level9Desc
          WHEN 'Level10Desc' THEN Level10Desc
          ELSE 'ESSetupId'
        END
    END ASC, CASE
      WHEN @SortOrder = -1 THEN CASE @SortColumn
          WHEN 'Level1Desc' THEN Level1Desc
          WHEN 'Level2Desc' THEN Level2Desc
          WHEN 'Level3Desc' THEN Level3Desc
          WHEN 'Level4Desc' THEN Level4Desc
          WHEN 'Level5Desc' THEN Level5Desc
          WHEN 'Level6Desc' THEN Level6Desc
          WHEN 'Level7Desc' THEN Level7Desc
          WHEN 'Level8Desc' THEN Level8Desc
          WHEN 'Level9Desc' THEN Level9Desc
          WHEN 'Level10Desc' THEN Level10Desc
          ELSE 'ESSetupId'
        END
    END DESC

    OFFSET @RecordFrom ROWS
    FETCH NEXT @PageSize ROWS ONLY
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_ManagementStructure_GetList',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +
            ',@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END
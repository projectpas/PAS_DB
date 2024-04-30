﻿/***************************************************************  
 ** File:   [USP_SingleScreen_new_AddUpdateData]             
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to add/update data
 ** Purpose:           
 ** Date:   04/02/2024  
            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  	Change Description              
 ** --   --------     -------		--------------------------------            
    1    04/02/2024   Vishal Suthar	 Created
	2	 05/04/2024   Bhargav saliya resolved credit-terms days and netdays updates issue in single screnn
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SingleScreen_New_AddUpdateData]
 @ID int = NULL,    
 @PageName varchar(100) = NULL,    
 @Fields SingleScreenColumnType READONLY,    
 @Mode varchar(50) = NULL,    
 @PrimaryKey varchar(100) = NULL,    
 @ReferenceTable varchar(100) = NULL,    
 @ManagementStructure bit,    
 @ManagementStructureTable varchar(100) = NULL,    
 @ManagementStructureIds varchar(100) = NULL    
AS    
BEGIN    
  SET NOCOUNT ON;    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  BEGIN TRY    
    DECLARE @Erorr AS varchar(max)    
    DECLARE @FieldName AS varchar(max)    
    DECLARE @FieldValue AS varchar(max)    
    DECLARE @Query AS varchar(max) = ''    
    DECLARE @selectedcompanyidsFieldName AS varchar(max) = ''    
    DECLARE @selectedcompanyidsFieldValue AS varchar(max) = ''    
    DECLARE @Isselectedcompany AS bit = 0    
    DECLARE @MasterCompanyId int = 0    
    DECLARE @CreatedBy varchar(max)    
    DECLARE @UpdatedBy varchar(max)    
    
    DECLARE @RefFieldName AS varchar(max)    
    DECLARE @RefFieldValue AS varchar(max)    
    DECLARE @RefColumnName AS varchar(max)    
    DECLARE @RefColumnValue AS bigint    
    DECLARE @RefQuery AS varchar(max) = ''    
    
    IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @PageName))    
    BEGIN    
      SET @Erorr = @PageName + ' Screen table is not available';    
      RAISERROR (@Erorr, 16, 1);    
      RETURN    
    END    
  
	--IF(@PageName = 'CustomerSettings')  
	--BEGIN
	--IF EXISTS(SELECT FieldValue FROM @Fields WHERE FieldName = 'IsDefault' AND FieldValue = 'true')
	--	BEGIN
	--		UPDATE CustomerSettings SET IsDefault = 0 WHERE MasterCompanyId = (SELECT TOP 1 FieldValue FROM @Fields WHERE FieldName = 'MasterCompanyId')
	--	END
	--END  
    
    SELECT TOP 1 @selectedcompanyidsFieldName = FieldName, @selectedcompanyidsFieldValue = FieldValue FROM @Fields WHERE FieldName = 'selectedcompanyids'    
    
    SET @Isselectedcompany = 0    
    IF (ISNULL(@selectedcompanyidsFieldName, '') != '')    
    BEGIN    
      SET @Isselectedcompany = 1    
    END    
    
    SELECT TOP 1 @MasterCompanyId = FieldValue FROM @Fields WHERE FieldName = 'MasterCompanyId'    
    SELECT TOP 1 @CreatedBy = FieldValue FROM @Fields WHERE FieldName = 'CreatedBy'    
    SELECT TOP 1 @UpdatedBy = FieldValue FROM @Fields WHERE FieldName = 'UpdatedBy'    
    
    IF (@Mode = 'Add')    
    BEGIN    
      IF (ISNULL(@ReferenceTable, '') != '')    
      BEGIN    
        SELECT @RefFieldName = COALESCE(@RefFieldName + ',  ' + FieldName, FieldName) FROM @Fields    
        WHERE FieldName != 'selectedcompanyids' AND ISNULL(ReferenceTable, '') != ''    
    
        SELECT @RefFieldValue = COALESCE(@RefFieldValue + ' ' +    
          (CASE    
            WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','    
            WHEN FieldType = 'boolean' THEN (CASE    
                WHEN LOWER(REPLACE(FieldValue, '''', '''''')) = 'true' THEN '1,'    
                ELSE '0,'    
              END)    
            WHEN FieldType = 'integer' OR FieldType = 'int' OR FieldType = 'number' THEN REPLACE(FieldValue, '''', '''''') + ','    
          END),    
          (CASE    
            WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','    
            WHEN FieldType = 'boolean' THEN (CASE    
                WHEN LOWER(REPLACE(FieldValue, '''', '''''')) = 'true' THEN '1,'    
                ELSE '0,'    
              END)    
            WHEN FieldType = 'integer' OR    
              FieldType = 'int' OR    
              FieldType = 'number' THEN REPLACE(FieldValue, '''', '''''') + ','    
          END))    
        FROM @Fields    
        WHERE FieldName != 'selectedcompanyids'    
        AND ISNULL(ReferenceTable, '') != ''    
    
        SET @RefFieldName += ' , MasterCompanyId, CreatedBy, UpdatedBy'    
        SET @RefFieldValue += ' ' + CAST(@MasterCompanyId AS varchar(max)) + ',''' + @CreatedBy + ''',''' + @CreatedBy + ''''    
    
        SET @RefQuery = 'INSERT INTO ' + @ReferenceTable + ' (' + @RefFieldName + ' )' + ' VALUES (' + @RefFieldValue + ')'    
    
        EXEC (@RefQuery)    
    
        SET @RefColumnValue = IDENT_CURRENT(@ReferenceTable)    
    
        SELECT @RefColumnName = [name] FROM SYS.COLUMNS WHERE is_identity = 1 AND OBJECT_NAME([object_id]) = @ReferenceTable    
      END    
    
      SELECT @FieldName = COALESCE(@FieldName + ',  ' + FieldName, FieldName) FROM @Fields    
      WHERE FieldName != 'selectedcompanyids'    
      AND ISNULL(ReferenceTable, '') = ''    
    
      SELECT @FieldValue = COALESCE(@FieldValue + ' ' +    
        (CASE    
          WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','    
          WHEN FieldType = 'boolean' THEN (CASE    
              WHEN LOWER(REPLACE(FieldValue, '''', '''''')) = 'true' THEN '1,'    
              ELSE '0,'    
            END)    
          WHEN LOWER(FieldType) = 'datetime' OR    
            LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'    
          WHEN FieldType = 'integer' OR FieldType = 'int' OR FieldType = 'number' THEN FieldValue + ','    
        END),    
        (CASE    
          WHEN FieldType = 'string' THEN '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','    
          WHEN FieldType = 'boolean' THEN (CASE    
              WHEN LOWER(REPLACE(FieldValue, '''', '''''')) = 'true' THEN '1,'    
              ELSE '0,'    
            END)    
          WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN 'CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'    
          WHEN FieldType = 'integer' OR FieldType = 'int' OR FieldType = 'number' THEN FieldValue + ','    
        END))    
      FROM @Fields    
      WHERE FieldName != 'selectedcompanyids' AND ISNULL(ReferenceTable, '') = ''    
    
      SET @FieldName = SUBSTRING(@FieldName, 1, LEN(@FieldName))    
      SET @FieldValue = SUBSTRING(@FieldValue, 1, LEN(@FieldValue) - 1)    
         
      IF (ISNULL(@ReferenceTable, '') != '')    
      BEGIN    
        SET @FieldName += ' ,' + @RefColumnName    
        SET @FieldValue += ' ,' + CAST(@RefColumnValue AS varchar(max))    
      END    
      SET @Query = 'INSERT INTO [' + @PageName + '] (' + @FieldName + ' )' + ' VALUES (' + @FieldValue + ')'    
          
      EXEC (@Query)    
    
      SET @ID = IDENT_CURRENT(@PageName)    
    END    
    ELSE    
    BEGIN	  
	  --EXEC [DBO].[USP_InsertAuditDataForSingleScreen] @ID,@PageName,@PrimaryKey 
      SET @Query = 'SELECT * FROM [' + @PageName + '] WHERE ' + @PrimaryKey + ' = ' + CAST(@ID AS varchar(100))    
    
      SELECT    
        @FieldValue = COALESCE(@FieldValue + '  ' + (CASE    
          WHEN FieldType = 'string' THEN FieldName + '=' + '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','    
          WHEN FieldType = 'boolean' THEN FieldName + '=' + (CASE WHEN LOWER(REPLACE(FieldValue, '''', '''''')) = 'true' THEN '1,' ELSE '0,'  END)    
          WHEN LOWER(FieldType) = 'datetime' OR LOWER(FieldType) = 'date' THEN FieldName + '= CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'    
          WHEN FieldType = 'integer' THEN FieldName + ' = ' + FieldValue + ',' ELSE CASE
									 WHEN FieldType = 'number' THEN FieldName + ' = ' + FieldValue + ',' ELSE '' end
		  END)
		  , 
		  (CASE WHEN FieldType = 'string' THEN FieldName + '=' + '''' + ISNULL(REPLACE(FieldValue, '''', ''''''), '') + ''','    
				WHEN FieldType = 'boolean' THEN FieldName + '=' + (CASE WHEN LOWER(REPLACE(FieldValue, '''', '''''')) = 'true' THEN '1,' ELSE '0,' END)    
				WHEN	LOWER(FieldType) = 'datetime' OR    
						LOWER(FieldType) = 'date' THEN FieldName + '= CONVERT(DATETIME,''' + REPLACE(FieldValue, '''', '''''') + ''',101),'    
				WHEN FieldType = 'integer' OR FieldType = 'int' OR FieldType = 'number' THEN FieldName + '=' + REPLACE(FieldValue, '''', '''''') + ','    
				ELSE '' END))    
      FROM @Fields WHERE FieldName != 'selectedcompanyids' AND ISNULL(ReferenceTable, '') = ''    
    
      SET @FieldValue = SUBSTRING(@FieldValue, 1, LEN(@FieldValue) - 1)  
    
      SET @Query = 'UPDATE [' + @PageName + '] SET ' + @FieldValue + ' , UpDatedDate = GETUTCDATE() WHERE ' + @PrimaryKey + '=' + CAST(@ID AS varchar(100))    

      EXEC (@Query)    
    
      IF (ISNULL(@ReferenceTable, '') != '')    
      BEGIN    
        SELECT    
          @RefFieldName = COALESCE(@RefFieldName + '  ' + (CASE    
            WHEN FieldType = 'string' THEN FieldName + '=' + '''' + ISNULL(FieldValue, '') + ''','    
            WHEN FieldType = 'boolean' THEN FieldName + '=' + (CASE    
                WHEN LOWER(FieldValue) = 'true' THEN '1,'    
                ELSE '0,'    
              END)    
            WHEN FieldType = 'integer' THEN FieldName + '=' + FieldValue + ','    
          END), (CASE    
            WHEN FieldType = 'string' THEN FieldName + '=' + '''' + ISNULL(FieldValue, '') + ''','    
            WHEN FieldType = 'boolean' THEN FieldName + '=' + (CASE    
                WHEN LOWER(FieldValue) = 'true' THEN '1,'    
                ELSE '0,'    
              END)    
            WHEN FieldType = 'integer' OR FieldType = 'int' OR FieldType = 'number' THEN FieldName + '=' + FieldValue + ','    
          END)) FROM @Fields WHERE FieldName != 'selectedcompanyids' AND ISNULL(ReferenceTable, '') != ''    
    
        SET @RefFieldName = SUBSTRING(@RefFieldName, 1, LEN(@RefFieldName) - 1)    
    
        SELECT @RefColumnName = [name] FROM SYS.COLUMNS WHERE is_identity = 1 AND OBJECT_NAME([object_id]) = @ReferenceTable    
    
        DECLARE @SqlQuery nvarchar(max)    
        SET @SqlQuery = 'SELECT TOP (1) @RefColumnValue = ([' + @RefColumnName + ']) FROM ' + @PageName + ' WHERE  ' + @PrimaryKey + '=' + CAST(@ID AS varchar(100))    
            
  EXEC SP_EXECUTESQL @SqlQuery, N'@RefColumnValue bigint OUTPUT', @RefColumnValue = @RefColumnValue OUTPUT    
    
        SET @RefQuery = ''    
        SET @RefQuery = 'UPDATE ' + @ReferenceTable + ' SET ' + @RefFieldName + ' WHERE ' + @RefColumnName + '=' + CAST(REPLACE(@RefColumnValue,'''', '''''') AS varchar(100)) + ''    
    
        EXEC (@RefQuery)    
      END    
    
    IF(@Isselectedcompany=1)    
    BEGIN    
     IF (@PageName = 'assetIntangibleType')    
     BEGIN    
       DELETE FROM [dbo].[AssetIntangibleTypeLEMapping] WHERE [IntangibleTypeId] =@ID     
     END         
  ELSE  IF (@PageName = 'assettangibletype')    
     BEGIN    
      DELETE FROM [dbo].[AssetTangibleTypeLEMapping] WHERE [TangibleTypeId] =@ID    
     END    
    END    
    END    
    
    IF (@Isselectedcompany = 1)    
    BEGIN    
      DECLARE @legalEntities AS varchar(max)    
    
    SET @legalEntities=(SELECT [Name] + ',' FROM DBO.LegalEntity WITH (NOLOCK) WHERE LegalEntityId IN (SELECT * FROM SplitString(@selectedcompanyidsFieldValue,',') ) FOR XML PATH(''))    
    IF(LEN(@legalEntities)>1)    
    BEGIN    
     SET @legalEntities=SUBSTRING(@legalEntities,1,LEN(@legalEntities)-1)          
    END     
    
  IF (@PageName = 'assetIntangibleType')    
    BEGIN    
      INSERT INTO [dbo].[AssetIntangibleTypeLEMapping] (IntangibleTypeId,LegalEntityId)    
      SELECT @ID,* FROM SplitString(@selectedcompanyidsFieldValue,',')    
      --UPDATE AssetIntangibleAttributeTypeAudit SET LegalEntity=  @legalEntities  WHERE AssetIntangibleAttributeTypeId =@ID      
  END    
  ELSE  IF (@PageName = 'assettangibletype')     
  BEGIN    
      INSERT INTO [dbo].[AssetTangibleTypeLEMapping] (TangibleTypeId,LegalEntityId)    
      SELECT @ID,* FROM SplitString(@selectedcompanyidsFieldValue,',')    
    
      --UPDATE AssetAttributeTypeAudit SET LegalEntity=@legalEntities  WHERE AssetAttributeTypeId =@ID         
  END    
    END    
    
    IF (@ManagementStructure = 1)    
    BEGIN    
      DECLARE @SQLQuery2 AS nvarchar(max) = NULL    
      DECLARE @DeleteSQLQuery AS nvarchar(max) = NULL    
      IF (@Mode = 'Edit')    
      BEGIN    
        SET @DeleteSQLQuery = 'DELETE FROM ' + @ManagementStructureTable + ' WHERE MasterCompanyId = ' + CAST(@MasterCompanyId AS varchar(max)) + ' AND ' + @PrimaryKey + ' = ' + CAST(@ID AS varchar(max)) + '';    
        EXECUTE (@DeleteSQLQuery)    
      END    
    
      SET @SQLQuery2 = 'INSERT INTO ' + @ManagementStructureTable + '(EntityStructureId,' + @PrimaryKey + ',MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted)'    
    
      SET @SQLQuery2 += ' SELECT  CAST(Item AS bigint), ' + CAST(@ID AS varchar(max)) + ',' + CAST(@MasterCompanyId AS varchar(max)) + ',' + @UpdatedBy + ',GETUTCDATE(), ' + @UpdatedBy + ', GETUTCDATE(),1,0 FROM dbo.SplitString(''' + @ManagementStructureIds + ''','','')';    
    
      EXECUTE (@SQLQuery2)    
    END    
    
	EXEC [dbo].[USP_SingleScreen_UpdateMasterSettings] @PageName, @ID    
  END TRY    
  BEGIN CATCH    
    DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME()    
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            ,@AdhocComments varchar(150) = 'USP_SingleScreen_New_AddUpdateData',    
            @ProcedureParameters varchar(3000) = '@ID = ''' + CAST(ISNULL(@ID, '') AS varchar(100))    
            + '@PageName = ''' + CAST(ISNULL(@PageName, '') AS varchar(100))    
            + '@Mode = ''' + CAST(ISNULL(@Mode, '') AS varchar(100))    
            + '@PrimaryKey = ''' + CAST(ISNULL(@PrimaryKey, '') AS varchar(100)),    
            @ApplicationName varchar(100) = 'PAS'    
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
    EXEC spLogException @DatabaseName = @DatabaseName,    
                        @AdhocComments = @AdhocComments,    
                        @ProcedureParameters = @ProcedureParameters,    
                        @ApplicationName = @ApplicationName,    
                        @ErrorLogID = @ErrorLogID OUTPUT;    
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
  END CATCH    
END
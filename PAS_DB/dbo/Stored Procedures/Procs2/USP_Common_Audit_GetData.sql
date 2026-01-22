/***************************************************************  
 ** File:   [USP_Common_Audit_GetData]             
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get Common history data
 ** Purpose:           
 ** Date:   13/06/2022  
            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		 Change Description              
 ** --   --------     -------		 --------------------------------            
    1    14/07/2022   Vishal Suthar	 Created  
    2    12/03/2025   Ayushi Patel   converted the date into utc (created , updated) , Added a case to get timeZone
-- EXEC USP_Common_Audit_GetData 'vw_ItemMasterCapesAudit',65,0
-- EXEC USP_Common_Audit_GetData 'vw_CustomerClassificationAudit',8, 0

-- exec USP_Common_Audit_GetData @ViewName=N'vw_PublicationTypeAudit',@Id=70,@ModuleId=0,@EmployeeId=229
**************************************************************/
CREATE PROCEDURE [dbo].[USP_Common_Audit_GetData]
    @ViewName VARCHAR(100) = NULL,
    @Id INT = NULL,
    @ModuleId INT = NULL,
	  @EmployeeId bigint
AS
BEGIN
    DECLARE @Query1 AS VARCHAR(MAX);
    DECLARE @Query2 AS VARCHAR(MAX);
    DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
    DECLARE @CreatedColumn AS VARCHAR(100);
    DECLARE @UpdatedColumn AS VARCHAR(100);

    -- Get the employee's time zone
    SELECT @CurrntEmpTimeZoneDesc = COALESCE(
        ETZ.[Description],  
        LTZ.[Description]   
    )
    FROM dbo.Employee E WITH (NOLOCK) 
    LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) 
        ON E.TimeZoneId = ETZ.TimeZoneId
    LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) 
        ON E.LegalEntityId = LE.LegalEntityId
    LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK)

        ON LE.TimeZoneId = LTZ.TimeZoneId
    WHERE E.EmployeeId =  @EmployeeId;

    -- Get the actual column names for Created and Updated Dates
    SELECT @CreatedColumn = COLUMN_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = @ViewName 
    AND COLUMN_NAME IN ('Created Date', 'Created On');

    SELECT @UpdatedColumn = COLUMN_NAME 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = @ViewName 
    AND COLUMN_NAME IN ('Updated Date', 'Updated On');

    -- Get column information
    SET @Query1 = 'SELECT COLUMN_NAME AS headerName, COLUMN_NAME AS fieldName, DATA_TYPE AS dataType 
                   FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''' + @ViewName + '''';

    -- Create and populate the temporary table
    SET @Query2 = 'SELECT * INTO #TempAuditData FROM [' + @ViewName + '] WHERE ID = ' + CAST(@Id AS VARCHAR(100));
    
    IF(@ModuleId <> 0)
    BEGIN
        SET @Query2 = @Query2 + ' AND ModuleID = ' + CAST(@ModuleId AS VARCHAR(100));
    END
    
    SET @Query2 = @Query2 + ' ORDER BY [PkID] DESC;';

    -- Convert the relevant date columns to local time zone if they exist
    IF @CreatedColumn IS NOT NULL
    BEGIN
        SET @Query2 = @Query2 + ' UPDATE #TempAuditData 
                                  SET [' + @CreatedColumn + '] = DBO.ConvertUTCtoLocal([' + @CreatedColumn + '], ''' + @CurrntEmpTimeZoneDesc + ''');';
    END
    
    IF @UpdatedColumn IS NOT NULL
    BEGIN
        SET @Query2 = @Query2 + ' UPDATE #TempAuditData 
                                  SET [' + @UpdatedColumn + '] = DBO.ConvertUTCtoLocal([' + @UpdatedColumn + '], ''' + @CurrntEmpTimeZoneDesc + ''');';
    END

    -- Select final data
    SET @Query2 = @Query2 + ' SELECT * FROM #TempAuditData; DROP TABLE #TempAuditData;';

    EXEC (@Query1);
    EXEC (@Query2);
END
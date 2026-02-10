/*************************************************************           
 ** File:   [USP_GetManagementStructureTypeByMasterCompanyId]           
 ** Author: Priyansh Patel
 ** Description: This stored procedure is used to retrieve Management Structure Types
 ** Purpose: Get TypeID, Description and SequenceNo by MasterCompanyId       
 ** Date:   02/09/2026 

 ** PARAMETERS:           
 ** @MasterCompanyId INT           
 ** RETURN VALUE:           
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author            Change Description            
 ** --   --------     -------           --------------------------------          
    1    02/09/2026   Priyansh Patel     Created     
**************************************************************/  
--EXEC [USP_GetManagementStructureTypeByMasterCompanyId] 1

CREATE     PROCEDURE [dbo].[USP_GetManagementStructureTypeByMasterCompanyId]
(
    @mastercompanyid INT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        IF OBJECT_ID(N'tempdb..#TempMSLevel') IS NOT NULL    
            DROP TABLE #TempMSLevel;  

        CREATE TABLE #TempMSLevel
        (
            SequenceNo INT,
            FieldName  VARCHAR(20),
            HeaderName NVARCHAR(200)
        );

        -- Insert actual management structure levels
        INSERT INTO #TempMSLevel (SequenceNo, FieldName, HeaderName)
        SELECT  
            SequenceNo,
            'level' + CAST(SequenceNo AS VARCHAR(10)),
            [Description]
        FROM dbo.ManagementStructureType WITH (NOLOCK)
        WHERE MasterCompanyId = @MasterCompanyId
          AND ISNULL(IsDeleted,0) = 0;

        DECLARE @count INT;
        SELECT @count = COUNT(*) FROM #TempMSLevel;

        -- Ensure always 10 levels (SSRS safe)
        WHILE @count < 10
        BEGIN
            INSERT INTO #TempMSLevel
            VALUES
            (
                @count + 1,
                'level' + CAST(@count + 1 AS VARCHAR(10)),
                NULL
            );
            SET @count = @count + 1;
        END;

        DECLARE @cols NVARCHAR(MAX);
        DECLARE @sql NVARCHAR(MAX);

        SELECT @cols = STUFF
        (
            (
                SELECT ',' + QUOTENAME(FieldName)
                FROM #TempMSLevel
                ORDER BY SequenceNo
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'),
            1,1,''
        );

        SET @sql = '
        SELECT ' + @cols + '
        FROM
        (
            SELECT FieldName, HeaderName
            FROM #TempMSLevel
        ) S
        PIVOT
        (
            MAX(HeaderName)
            FOR FieldName IN (' + @cols + ')
        ) P;';

        EXEC (@sql);

        IF OBJECT_ID(N'tempdb..#TempMSLevel') IS NOT NULL    
        BEGIN    
            DROP TABLE #TempMSLevel;  
        END 



    END TRY
    BEGIN CATCH

        DECLARE @ErrorLogID INT  
              ,@DatabaseName VARCHAR(100) = DB_NAME()  
               -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              ,@AdhocComments VARCHAR(150) = 'USP_GetManagementStructureTypeByMasterCompanyId'  
              ,@ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))  
              ,@ApplicationName VARCHAR(100) = 'PAS';  
  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
        EXEC spLogException  
            @DatabaseName = @DatabaseName,  
            @AdhocComments = @AdhocComments,  
            @ProcedureParameters = @ProcedureParameters,  
            @ApplicationName = @ApplicationName,  
            @ErrorLogID = @ErrorLogID OUTPUT;  

        RAISERROR (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );  

        RETURN (1);             

    END CATCH
END
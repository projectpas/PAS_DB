/*
Author: sqiller
Description: Searches for a value to replace in all columns from all tables
USE: EXEC dbo.usp_Update_AllTAbles 'work', 'sqiller', 1
@search = Value to look for Replace
@newvalue = the value that will replace @search
@Test = If set to 1, it will only PRINT the UPDATE statement instead of EXEC, useful to see
        what is going to update before.
*/
--EXEC dbo.usp_Update_AllTAbles 'CREATEDBY', 'Larry', 0
CREATE PROCEDURE [dbo].[usp_Update_AllTAbles] (@search varchar(100),
@newvalue varchar(100),
@Test bit)
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY

    BEGIN TRANSACTION
      IF NOT EXISTS (SELECT
          1
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_NAME = 'Tables_to_Update')
      BEGIN
        CREATE TABLE dbo.Tables_to_Update (
          Table_name varchar(100),
          Column_name varchar(100),
          recordsToUpdate int
        )
      END
      DECLARE @table varchar(100)
      DECLARE @column varchar(100)
      DECLARE @SQL varchar(max)

      SELECT
        TABLE_SCHEMA + '.' + TABLE_NAME AS Table_Name,
        0 AS Processed INTO #tables
      FROM information_schema.tables
      WHERE TABLE_TYPE != 'VIEW'

      WHILE EXISTS (SELECT
          *
        FROM #tables
        WHERE processed = 0)
      BEGIN
        SELECT TOP 1
          @table = table_name
        FROM #tables
        WHERE processed = 0

        SELECT
          column_name,
          0 AS Processed INTO #columns
        FROM information_schema.columns
        WHERE TABLE_SCHEMA + '.' + TABLE_NAME = @table


        WHILE EXISTS (SELECT
            *
          FROM #columns
          WHERE processed = 0)
        BEGIN

          SELECT TOP 1
            @column = COLUMN_NAME
          FROM #columns
          WHERE processed = 0
          IF @column = 'CreatedBy'
            OR @column = 'UpdatedBy'
          BEGIN

            SET @SQL = 'INSERT INTO Tables_to_Update
                                select ''' + @table + ''', ''' + @column + ''', count(*) from ' + @table + ' where ' + @column + ' like ''%' + @search + '%'''
            EXEC (@SQL)

            IF EXISTS (SELECT
                *
              FROM Tables_to_Update WITH (NOLOCK)
              WHERE Table_name = @table)
            BEGIN
              SET @SQL = 'UPDATE ' + @table + ' SET ' + @column + ' = REPLACE(''' + 'UPDATEDBY' + ''',''' + 'UPDATEDBY' + ''',''' + 'Larry' + ''')  WHERE ' + @column + ' like ''%' + @search + '%'''
              --UPDATE HERE
              IF (@Test = 1)
              BEGIN
                PRINT @SQL
              END
              ELSE
              BEGIN
                EXEC (@SQL)
              END
            END
          END

          UPDATE #columns
          SET Processed = 1
          WHERE COLUMN_NAME = @column
        END

        DROP TABLE #columns

        UPDATE #tables
        SET Processed = 1
        WHERE table_name = @table
      END

      SELECT
        *
      FROM Tables_to_Update WITH (NOLOCK)
      WHERE recordsToUpdate > 0
    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
      PRINT 'ROLLBACK'
    ROLLBACK TRAN;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = 'usp_Update_AllTAbles',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + ISNULL(@search, '') + ''', 
													   @Parameter3 = ' + ISNULL(@newvalue, '') + ', 
													   @Parameter4 = ' + CAST(ISNULL(@Test, '') AS varchar) + '',
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
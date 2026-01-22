-- =============================================
-- Author:  	Vishal Suthar
-- Create date: 09-June-2021
-- Description:	Get Search Data Logs
-- =============================================
CREATE PROCEDURE [dbo].[SearchLogData]
-- Add the parameters for the stored procedure here
@PageNumber int,
@PageSize int,
@SortColumn varchar(50) = NULL,
@SortOrder int,
@GlobalFilter varchar(50) = NULL,
@Exception nvarchar(max) = NULL,
@Message nvarchar(max) = NULL,
@MessageTemplate nvarchar(max) = NULL,
@Properties nvarchar(max) = NULL,
@Level varchar(50) = NULL,
@Timestamp datetime = NULL,
@FromDate datetime = NULL,
@ToDate datetime = NULL
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRANSACTION
      DECLARE @RecordFrom int;
      SET @RecordFrom = (@PageNumber - 1) * @PageSize;

      -- Insert statements for procedure here
      ;
      WITH Result
      AS (SELECT
        Id,
        [Message],
        MessageTemplate,
        [Level],
        [TimeStamp],
        Exception,
        Properties
      FROM DBO.[Log] WITH (NOLOCK)),
      FinalResult
      AS (SELECT
        Id,
        [Message],
        MessageTemplate,
        [Level],
        [TimeStamp],
        Exception,
        Properties
      FROM Result
      WHERE (
      (@GlobalFilter <> ''
      AND (([Message] LIKE '%' + @GlobalFilter + '%')
      OR (MessageTemplate LIKE '%' + @GlobalFilter + '%')
      OR ([Level] LIKE '%' + @GlobalFilter + '%')
      OR ([TimeStamp] LIKE '%' + @GlobalFilter + '%')
      OR (Exception LIKE '%' + @GlobalFilter + '%')
      OR (Properties LIKE '%' + @GlobalFilter + '%')
      ))
      OR (@GlobalFilter = ''
      AND (ISNULL(@Message, '') = ''
      OR Message LIKE '%' + @Message + '%')
      AND (ISNULL(@MessageTemplate, '') = ''
      OR MessageTemplate LIKE '%' + @MessageTemplate + '%')
      AND (ISNULL(@Level, '') = ''
      OR Level LIKE '%' + @Level + '%')
      AND (@TimeStamp IS NULL
      OR CAST(TimeStamp AS date) = CAST(@TimeStamp AS date))
      AND (ISNULL(@Exception, '') = ''
      OR Exception LIKE '%' + @Exception + '%')
      AND (ISNULL(@Properties, '') = ''
      OR Properties LIKE '%' + @Properties + '%')
      AND (@FromDate IS NULL
      OR @ToDate IS NULL
      OR CAST([TimeStamp] AS date) BETWEEN CAST(@FromDate AS date) AND CAST(@ToDate AS date)))
      )),
      ResultCount
      AS (SELECT
        COUNT(Id) AS NumberOfItems
      FROM FinalResult)
      SELECT
        Id,
        [Message],
        MessageTemplate,
        [Level],
        [TimeStamp],
        Exception,
        Properties,
        NumberOfItems
      FROM FinalResult,
           ResultCount
      ORDER BY CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'MESSAGE') THEN Message
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'MESSAGETEMPLATE') THEN MessageTemplate
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'LEVEL') THEN Level
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'TIMESTAMP') THEN TimeStamp
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'EXCEPTION') THEN Exception
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'PROPERTIES') THEN Properties
      END ASC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'MESSAGE') THEN Message
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'MESSAGETEMPLATE') THEN MessageTemplate
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'LEVEL') THEN Level
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'TIMESTAMP') THEN TimeStamp
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'EXCEPTION') THEN Exception
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'PROPERTIES') THEN Properties
      END DESC
      OFFSET @RecordFrom ROWS
      FETCH NEXT @PageSize ROWS ONLY
      PRINT @SortOrder
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
            @AdhocComments varchar(150) = 'SearchLogData',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + ISNULL(@PageNumber, '') + ''', 
													   @Parameter2 = ' + ISNULL(@PageSize, '') + ', 
													   @Parameter3 = ' + ISNULL(@SortColumn, '') + ', 
													   @Parameter4 = ' + ISNULL(@SortOrder, '') + ', 
													   @Parameter6 = ' + ISNULL(@GlobalFilter, '') + '',
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
/*************************************************************           
 ** File:   [dbo].[[USP_GetReceivingCustomerPartsLIstData]]          
 ** Author:   BHARGAV SALIYA
 ** Description: Get WO dashboard data(Receiving Parts Data)
 ** Date:   09-Dec-2024   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09-Dec-2024   BHARGAV SALIYA    Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetReceivingCustomerPartsLIstData] 
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50) = null,
	@SortOrder int = -1,
	@Customer varchar(256) = null,
	@PartNumber varchar(100) = null,
	@RecevingParts varchar(50) = null,
	@MasterCompanyId int = null,
	@StartDate datetime = null

AS
BEGIN

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				
				DECLARE @RecordFrom int;
				
				SET @RecordFrom = (@PageNumber-1) * @PageSize;
				
				IF @SortColumn IS NULL
				BEGIN
					SET @SortColumn = 'StartDate';
					SET @SortOrder=-1;
				END 
				ELSE
				BEGIN 
					SET @SortColumn = Upper(@SortColumn)
				END

				IF OBJECT_ID(N'tempdb..#finalResult') IS NOT NULL      
					BEGIN      
				DROP TABLE #finalResult    
				END

				IF OBJECT_ID('tempdb..#tmpTop10CustomerReceivedWOPart') IS NOT NULL
				DROP TABLE #tmpTop10CustomerReceivedWOPart;



				CREATE TABLE #tmpTop10CustomerReceivedWOPart
				(
					[RecordId] [bigint] IDENTITY(1,1),
					[CustomerId] [bigint] NULL,
					[CustomerName] [varchar](100) NULL,
					[PartNumber] [varchar](100) NULL,
					[MastercompanyId] [int] NULL,
					[RecevingParts] [int] NULL,
				);
				INSERT INTO #tmpTop10CustomerReceivedWOPart ([CustomerId], [CustomerName], [MastercompanyId],[RecevingParts])
				SELECT DISTINCT
					C.CustomerId, 
					C.[Name] as [CustomerName], 
					--RC.PartNumber,
					C.MasterCompanyId,
					COUNT(*) AS RecevingParts
				FROM [dbo].[ReceivingCustomerWork] RC WITH (NOLOCK)
				INNER JOIN dbo.Customer C WITH (NOLOCK) ON C.CustomerId = RC.CustomerId
				WHERE CONVERT(DATE, RC.ReceivedDate) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AND @StartDate 
					  AND RC.MasterCompanyId = @MasterCompanyId AND ISNULL(RC.IsPiecePart,0) = 0
					  GROUP BY C.CustomerId,C.[Name],C.MasterCompanyId


				SELECT * INTO #finalResult
				FROM #tmpTop10CustomerReceivedWOPart
				WHERE (
				(ISNULL(@Customer,'') ='' OR [CustomerName] LIKE '%' + @Customer+'%') AND
				(ISNULL(@RecevingParts,'') ='' OR [RecevingParts] LIKE '%' + @RecevingParts+'%') 
				)

				SELECT COUNT(2) OVER () AS NumberOfItems, [CustomerId], [CustomerName], [MastercompanyId],[RecevingParts]
			    FROM #finalResult 
			    ORDER BY 
				CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
					CASE WHEN (@SortOrder=1  AND @SortColumn='RecevingParts')  THEN RecevingParts END ASC,
					CASE WHEN (@SortOrder=-1 AND @SortColumn='RecevingParts')  THEN RecevingParts END DESC

			    OFFSET @RecordFrom ROWS 
			    FETCH NEXT @PageSize ROWS ONLY
			
			END
		COMMIT TRANSACTION
	END TRY


	BEGIN CATCH      
		IF @@trancount > 0
			ROLLBACK TRAN;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments VARCHAR(150) = 'USP_GetReceivingCustomerPartsLIstData' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
        ,@ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName         =  @DatabaseName
                ,@AdhocComments       =  @AdhocComments
                ,@ProcedureParameters =  @ProcedureParameters
                ,@ApplicationName     =  @ApplicationName
                ,@ErrorLogID          =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END
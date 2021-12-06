
/*************************************************************           
 ** File:   [UpdateWorkOrderQuoteVersionNo]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Update WorkOrder Version Number 
 ** Purpose:         
 ** Date:   06/28/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/28/2020   Hemant Saliya Created
     
-- EXEC [UpdateWorkOrderQuoteVersionNo] 50, 1
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateWorkOrderQuoteVersionNo]
@WorkOrderQuoteId INT,
@IsVersionIncrease BIT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	DECLARE @VersionNo VARCHAR(20);
	DECLARE @Version VARCHAR(20);
	DECLARE @SplitChar VARCHAR(20);
	DECLARE @VersionPrefix VARCHAR(20);
	SET @SplitChar = '-';
	

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				IF(@IsVersionIncrease = 1)
				BEGIN
					SELECT @VersionNo = VersionNo FROM dbo.WorkOrderQuote WITH(NOLOCK) WHERE WorkOrderQuoteId = @WorkOrderQuoteId;

					IF OBJECT_ID(N'tempdb..#CodePrifix') IS NOT NULL
					BEGIN
					DROP TABLE #CodePrifix
					END
	
					CREATE TABLE #CodePrifix
					(
						 ID BIGINT NOT NULL IDENTITY, 
						 items VARCHAR(100) NULL
					)

					INSERT INTO #CodePrifix (items) SELECT Item FROM DBO.SPLITSTRING(@VersionNo, @SplitChar)
					SELECT @VersionPrefix = items FROM #CodePrifix WHERE ID = 1
					SELECT @Version = items FROM #CodePrifix WHERE ID = 2					
					
					IF(@VersionNo != '' OR @VersionNo != NULL)
					BEGIN
						IF(CHARINDEX ('-',@VersionNo) > 0)
						--IF(LEN(@VersionNo) >= 5)
						BEGIN
							--SET @Version = STUFF(@VersionNo,1,4,'')
							--SELECT @Version;
							--SET @Version = 'V' + CAST(CAST(@Version AS INT) + 1 AS VARCHAR(20));
							SET @Version = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@Version AS INT) + 1, @VersionPrefix, ''))
						END
						ELSE
						BEGIN
							--SET @Version = STUFF(@VersionNo,1,1,'')
							--SET @Version = 'V' + CAST(CAST(@Version AS INT) + 1 AS VARCHAR(20));
							SET @Version = (SELECT * FROM dbo.udfGenerateCodeNumber(CAST(@Version AS INT) + 1,'VER', ''))
						END
					END
					ELSE
					BEGIN
						--SET @Version = 'VER-00001';
						SET @Version = (SELECT * FROM dbo.udfGenerateCodeNumber(1,'VER', ''))
					END

					UPDATE WOQ  
						SET WOQ.VersionNo = @Version					
					FROM [dbo].[WorkOrderQuote] WOQ
					WHERE WOQ.WorkOrderQuoteId = @WorkOrderQuoteId
				END
				
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteVersionNo' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@WorkOrderQuoteId, '') AS varchar(MAX)) + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
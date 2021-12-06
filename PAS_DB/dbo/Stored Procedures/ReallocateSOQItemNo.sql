﻿/*************************************************************
EXEC [dbo].[ReallocateSOQItemNo]  74
**************************************************************/ 
CREATE PROCEDURE [dbo].[ReallocateSOQItemNo]  
  @SalesOrderQuoteId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			;WITH Ranked
			AS
			(
			   SELECT *, CAST(DENSE_RANK() OVER(ORDER BY ItemMasterId, ConditionId, CreatedBy) AS INT) row_num
			   FROM DBO.SalesOrderQuotePart WITH (NOLOCK) Where SalesOrderQuoteId = @SalesOrderQuoteId
			   AND IsDeleted = 0
			)

			UPDATE Ranked
			SET ItemNo = row_num;

			SELECT PartNumber as [value] FROM SalesOrderQuotePart Where SalesOrderQuoteId = @SalesOrderQuoteId

		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'ReallocateSOQItemNo' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteId, '') + ''''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH    
END
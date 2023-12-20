/*************************************************************
EXEC [dbo].[GenerateShipmentNumber]  10
**************************************************************/ 
CREATE PROCEDURE [dbo].[GenerateShipmentNumber]  
  @SalesOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			;WITH Ranked
			AS
			(
				SELECT *, CAST(DENSE_RANK() OVER(ORDER BY SalesOrderId, SOShippingNum) AS INT) row_num
				FROM DBO.SalesOrderShipping WITH (NOLOCK) Where SalesOrderId = @SalesOrderId AND IsDeleted = 0
			)

			--SELECT * FROM Ranked
			UPDATE Ranked
			SET SmentNum = row_num;

			SELECT CustomerReference as [value] FROM SalesOrderPart Where SalesOrderId = @SalesOrderId
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'ReallocateItemNo' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''''
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
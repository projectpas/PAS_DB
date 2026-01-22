/*************************************************************           
 ** File:   [USP_VendorRMA_GenerateShipmentNumber]          
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to generate SmentNum.
 ** Purpose:         
 ** Date:   06/13/2023        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    06/30/2023   Amit Ghediya			Created
     
EXEC [dbo].[USP_VendorRMA_GenerateShipmentNumber]  10
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_VendorRMA_GenerateShipmentNumber]  
  @VendorRMAId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN
			;WITH Ranked
			AS
			(
				SELECT *, CAST(DENSE_RANK() OVER(ORDER BY VendorRMAId, RMAShippingNum) AS INT) row_num
				FROM DBO.RMAShipping WITH (NOLOCK) Where VendorRMAId = @VendorRMAId AND IsDeleted = 0
			)

			UPDATE Ranked
			SET SmentNum = row_num;

			--SELECT CustomerReference as [value] FROM VendorRMADetail Where VendorRMAId = @VendorRMAId
		END
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_GenerateShipmentNumber' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''''
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
/*************************************************************           
 ** File:     [USP_UpdateSubWOSerialNumber_ByPartId]           
 ** Author:	  Devendra Shekh
 ** Description: This SP IS Used to Update Serial Number For Sub WO Part
 ** Purpose:         
 ** Date:   05/29/2024	      [mm/dd/yyyy]    
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------				--------------------------------     
	1		05/29/2024		Devendra Shekh			CREATED
	
	EXEC [USP_UpdateSubWOSerialNumber_ByPartId] 'testSr44',238,'Admin User'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateSubWOSerialNumber_ByPartId]
@NewSerialNumber VARCHAR(50),
@SubWOPartNoId BIGINT,
@UserName VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				DECLARE @StockLineId BIGINT = 0;
				DECLARE @RevisedStkId BIGINT = 0;
				SELECT @StockLineId = ISNULL(SWP.StockLineId, 0), @RevisedStkId = ISNULL(SWP.RevisedStockLineId, 0) FROM [dbo].[SubWorkOrderPartNumber] SWP WITH(NOLOCK) WHERE SWP.SubWOPartNoId = @SubWOPartNoId;

				IF(@RevisedStkId > 0)
				BEGIN
					UPDATE RSTK
					SET RSTK.SerialNumber = @NewSerialNumber, RSTK.isSerialized = 1, RSTK.UpdatedBy = @UserName, RSTK.UpdatedDate = GETUTCDATE()
					FROM [DBO].[Stockline] RSTK WHERE RSTK.StockLineId = @RevisedStkId
				END
				ELSE
				BEGIN
					UPDATE STK
					SET STK.SerialNumber = @NewSerialNumber, STK.isSerialized = 1, STK.UpdatedBy = @UserName, STK.UpdatedDate = GETUTCDATE()
					FROM [DBO].[Stockline] STK WHERE STK.StockLineId = @StockLineId
				END

				UPDATE SWOP 
				SET SWOP.UpdatedBy = @UserName, SWOP.UpdatedDate = GETUTCDATE() , SWOP.islocked = CASE WHEN ISNULL(SWOP.islocked, 0) = 1 THEN 0 ELSE SWOP.islocked END
				FROM [dbo].[SubWorkOrderPartNumber] SWOP WHERE SWOP.SubWOPartNoId = @SubWOPartNoId;

				UPDATE WRO 
				SET WRO.Batchnumber = @NewSerialNumber,  WRO.UpdatedBy = @UserName, WRO.UpdatedDate = GETUTCDATE() 
				FROM [dbo].[SubWorkOrder_ReleaseFrom_8130] WRO WHERE WRO.SubWOPartNoId = @SubWOPartNoId;
				
			END
		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0				
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateSubWOSerialNumber_ByPartId' 
               ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@NewSerialNumber, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
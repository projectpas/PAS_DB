
/*************************************************************
 ** File:   [UpdateCustomeRMAPdfPath]
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used to Update Customer RMA Pdf Path
 ** Purpose:
 ** Date:   09/05/2022
 ** PARAMETERS: @RMAHeaderId  @PDFPath   
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/05/2022   Subhash Saliya    Created

 EXECUTE UpdateCustomeRMAPdfPath 24,'LOCAL_FILES/2/UploadFiles/WorkOrder/CreditMemoPDFPrint/CM#-000025.Pdf'

**************************************************************/ 
CREATE   PROCEDURE [dbo].[UpdateCustomeRMAPdfPath]      
@RMAHeaderId  bigint,
@PDFPath nvarchar(100)  
AS    
BEGIN    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
					UPDATE dbo.CustomerRMAHeader SET [PDFPath]=@PDFPath WHERE [RMAHeaderId] = @RMAHeaderId;
			END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateCustomeRMAPdfPath' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' +  CAST(ISNULL(@RMAHeaderId, '') as varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END
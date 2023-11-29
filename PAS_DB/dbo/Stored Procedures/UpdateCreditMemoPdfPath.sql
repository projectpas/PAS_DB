﻿
/*************************************************************
 ** File:   [UpdateCreditMemoPdfPath]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Update Credit Memo Pdf Path
 ** Purpose:
 ** Date:   09/05/2022
 ** PARAMETERS: @CreditMemoHeaderId  @PDFPath   
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/05/2022   Moin Bloch    Created

 EXECUTE UpdateCreditMemoPdfPath 24,'LOCAL_FILES/2/UploadFiles/WorkOrder/CreditMemoPDFPrint/CM#-000025.Pdf'

**************************************************************/ 
CREATE   PROCEDURE [dbo].[UpdateCreditMemoPdfPath]      
@CreditMemoHeaderId  bigint,
@PDFPath nvarchar(100)  
AS    
BEGIN    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
					UPDATE dbo.CreditMemo SET [PDFPath]=@PDFPath WHERE [CreditMemoHeaderId] = @CreditMemoHeaderId;
			END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateCreditMemoPdfPath' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' +  CAST(ISNULL(@CreditMemoHeaderId, '') as varchar(100))
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
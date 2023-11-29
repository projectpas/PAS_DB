/*************************************************************           
 ** File:   [RPT_GetStandAloneCreditMemoItemForPrint]           
 ** Author: Amit Ghediya
 ** Description: Get Stand Alone Customer Credit Memo for SSRS Report.
 ** Purpose:         
 ** Date:   13/09/2023    
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    13/09/2023   Amit Ghediya    Created
	
 --  EXEC RPT_GetStandAloneCreditMemoItemForPrint 13
**************************************************************/ 

CREATE     PROCEDURE [dbo].[RPT_GetStandAloneCreditMemoItemForPrint]
	@CreditMemoHeaderId bigint
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		SELECT 
			  ROW_NUMBER() OVER (
				ORDER BY SACM.StandAloneCreditMemoDetailId
			  ) row_num,
			  GL.AccountCode +' '+ GL.AccountName AS 'GLName',
			  ISNULL(GL.AccountDescription,'') AS 'Description',
			  SACM.Qty,
			  SACM.Rate,
			  SACM.Amount
		FROM dbo.StandAloneCreditMemoDetails SACM WITH (NOLOCK)	
		LEFT JOIN dbo.GLAccount GL WITH (NOLOCK) ON SACM.GlAccountId = GL.GLAccountId
		WHERE SACM.CreditMemoHeaderId = @CreditMemoHeaderId;
	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0				
	ROLLBACK TRAN;
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
    , @AdhocComments     VARCHAR(150)    = 'RPT_GetStandAloneCreditMemoItemForPrint' 
    , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@CreditMemoHeaderId AS varchar(10)) ,'') +''													  
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
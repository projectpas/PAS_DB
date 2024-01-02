/*************************************************************           
 ** File:   [UpdateWorkOrderPartNumberRevisedColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used WO Details based in WO Id.    
 ** Purpose:         
 ** Date:   10/27/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    10/27/2020   Subhash Saliya	Created
    2    01/01/2024   Devendra Shekh	added new param to update seialnumber
     
-- EXEC [UpdateWorkOrderPartNumberRevisedColumnsWithId] 30
**************************************************************/

CREATE   PROCEDURE [dbo].[UpdateWorkOrderPartNumberRevisedColumnsWithId]
	@WorkOrderPartNumberId BIGINT,
	@SerialNumber VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				UPDATE WPN SET 
					WPN.RevisedPartNumber = IM.PartNumber,
					WPN.RevisedPartDescription = IM.PartDescription,
					WPN.RevisedSerialNumber = @SerialNumber
				FROM dbo.WorkOrderPartNumber WPN WITH(NOLOCK) 
				LEFT JOIN ItemMaster IM ON IM.ItemMasterId = WPN.RevisedItemmasterid
				WHERE WPN.ID = @WorkOrderPartNumberId
		
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderPartNumberColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartNumberId, '') + '@Parameter1 = '''+ ISNULL(@SerialNumber, '') + ''
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
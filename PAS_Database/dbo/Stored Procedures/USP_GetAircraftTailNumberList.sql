/*************************************************************               
 ** File:   [USP_GetAircraftTailNumberList]               
 ** Author:  AMIT GHEDIYA    
 ** Description:  This Store Procedure use to get Aircraft TailNumber list.   
 ** Purpose:             
 ** Date:   15/05/2026          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** check customer emial & phone exists.             
 **********************************************************               
 ** PR   Date			Author			 Change Description                
 ** --   --------		-------			 --------------------------------              
    1    15/05/2026  	Abhishek Jirawla Created     
 
 EXEC [USP_GetAircraftTailNumberList] 'VT-BCL'
********************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_GetAircraftTailNumberList]
	@MasterCompanyId   INT
AS
BEGIN
		BEGIN TRY
			
			SELECT DISTINCT TailNum
            FROM dbo.AircraftRegistryHeader WITH(NOLOCK)
            WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 and IsDeleted = 0
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAircraftTailNumberList' 
              , @ProcedureParameters VARCHAR(3000)  = 'MasterCompanyId = '''+ ISNULL(@MasterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END
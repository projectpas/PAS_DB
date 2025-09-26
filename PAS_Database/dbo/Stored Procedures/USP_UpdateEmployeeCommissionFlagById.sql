/*************************************************************           
 ** File:   [USP_UpdateEmployeeCommissionFlagById]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Create or update Lot General Info
 ** Date:   15/02/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    15/02/2023   Rajesh Gami     Created
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_UpdateEmployeeCommissionFlagById]
(    
@PrimarySalesPersonId BIGINT = NULL,
@SecondarySalesPersonId BIGINT = NULL,
@CsrId BIGINT = NULL, 
@AgentId  BIGINT = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

		BEGIN TRY
	              
                    IF (@PrimarySalesPersonId IS NOT NULL AND @PrimarySalesPersonId > 0)
                    BEGIN
                        UPDATE dbo.Employee 
                        SET IsCommission = 1 
                        WHERE EmployeeId = @PrimarySalesPersonId;
                    END;

                    
                    IF (@SecondarySalesPersonId IS NOT NULL AND @SecondarySalesPersonId > 0)
                    BEGIN
                        UPDATE dbo.Employee 
                        SET IsCommission = 1 
                        WHERE EmployeeId = @SecondarySalesPersonId;
                    END;

                   
                    IF (@CsrId IS NOT NULL AND @CsrId > 0)
                    BEGIN
                        UPDATE dbo.Employee 
                        SET IsCommission = 1 
                        WHERE EmployeeId = @CsrId;
                    END;

                  
                    IF (@AgentId IS NOT NULL AND @AgentId > 0)
                    BEGIN
                        UPDATE dbo.Employee 
                        SET IsCommission = 1 
                        WHERE EmployeeId = @AgentId;
                    END;

		END TRY    
		BEGIN CATCH      
		
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateEmployeeCommissionFlagById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PrimarySalesPersonId, '') + ''
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
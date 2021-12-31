


/*************************************************************           
 ** File:   [AutoCompleteDropdownsTeardownReasons]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used retrieve Teardown List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   06/08/2020       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/08/2020   subhash Saliya Created
	2    06/29/2020   Hemant Saliya  Added Transation and Content Managment
     
--EXEC [AutoCompleteDropdownsTeardownReasons] '',20,'108,109,11'
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsTeardownReasons]
@TeardownTypeId bigint,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN  
				IF (@Count = '0') 
				BEGIN
					SET @Count = '20';
				END	
				SELECT 
					tr.TeardownReasonId AS Value, 
					tr.Reason AS Label
				FROM dbo.TeardownReason tr WITH(NOLOCK) 						
				WHERE (tr.IsActive = 1 AND ISNULL(tr.IsDeleted, 0) = 0 AND tr.CommonTeardownTypeId = @TeardownTypeId
					      AND tr.MasterCompanyId = @MasterCompanyId)    
				UNION     
				SELECT 
					tr.TeardownReasonId AS Value, 
					tr.Reason AS Label
				FROM dbo.TeardownReason tr WITH(NOLOCK) 
				WHERE tr.CommonTeardownTypeId = @TeardownTypeId AND tr.MasterCompanyId = @MasterCompanyId AND tr.TeardownReasonId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
				ORDER BY Label	
		--	END
		--COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			 --   IF @@trancount > 0
				--PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsTeardownReasons' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TeardownTypeId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@Idlist ,'') +'''
													   @Parameter3 = ' + ISNULL(CAST(@MasterCompanyId AS varchar(10)) ,'') +''
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
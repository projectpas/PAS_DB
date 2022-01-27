


/*************************************************************           
 ** File:   [AutoCompleteDropdownsTeardownRemovalReasons]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used retrieve Teardown removal List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   01/25/2022       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/25/2022   Vishal Suthar Created
     
--EXEC [AutoCompleteDropdownsTeardownRemovalReasons] '',20,'108,109,11'
**************************************************************/

CREATE PROCEDURE [dbo].[AutoCompleteDropdownsTeardownRemovalReasons]
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
				IF (@Count = '0') 
				BEGIN
					SET @Count = '20';
				END	

				DECLARE @removalTearDownTypeId AS BIGINT = 0;

				SELECT @removalTearDownTypeId = ctt.CommonTeardownTypeId FROM dbo.CommonTeardownType ctt WITH(NOLOCK) 						
				WHERE ctt.TearDownCode = 'RemovalReason' AND ctt.MasterCompanyId = @MasterCompanyId  

				SELECT 
					tr.TeardownReasonId AS Value, 
					tr.Reason AS Label
				FROM dbo.TeardownReason tr WITH(NOLOCK) 						
				WHERE (tr.IsActive = 1 AND ISNULL(tr.IsDeleted, 0) = 0 AND tr.CommonTeardownTypeId = @removalTearDownTypeId
					      AND tr.MasterCompanyId = @MasterCompanyId)   
		END TRY    
		BEGIN CATCH      
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsTeardownReasons' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@Idlist ,'') +'''
													   @Parameter2 = ' + ISNULL(CAST(@MasterCompanyId AS varchar(10)) ,'') +''
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
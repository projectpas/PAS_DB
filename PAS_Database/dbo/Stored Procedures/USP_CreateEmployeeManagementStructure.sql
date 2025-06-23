/*************************************************************           
 ** File:   [USP_CreateEmployeeManagementStructure]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Create EmployeeManagementStructure List
 ** Purpose:         
 ** Date:   20-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    20-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_CreateEmployeeManagementStructure]
    @EmployeeId BIGINT,
    @tbl_EmployeeManagementStructure [dbo].[EmployeeManagementStructureTVP] READONLY
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM @tbl_EmployeeManagementStructure)
        BEGIN
            DECLARE @EmpId BIGINT = (SELECT TOP 1 EmployeeId FROM @tbl_EmployeeManagementStructure);

            DELETE FROM [dbo].EmployeeManagementStructure WHERE EmployeeId = @EmpId;
        END
        ELSE
        BEGIN
            DELETE FROM [dbo].EmployeeManagementStructure WHERE EmployeeId = @EmployeeId;
        END

        INSERT INTO EmployeeManagementStructure (EmployeeId, ManagementStructureId, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsActive, IsDeleted)
        SELECT EmployeeId, ManagementStructureId, MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsActive, IsDeleted FROM @tbl_EmployeeManagementStructure;

        COMMIT;
    END TRY
   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_CreateEmployeeManagementStructure' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '') 

				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END
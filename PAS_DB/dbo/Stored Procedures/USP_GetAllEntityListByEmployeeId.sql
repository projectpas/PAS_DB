
/*************************************************************           
 ** File:   [USP_GetAllEntityListByEmployeeId]           
 ** Author:   Hemant Saliya
 ** Description: Get Entity Structure Managment List  
 ** Purpose:         
 ** Date:   09/15/2023     
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/15/2023   Hemant Saliya Created
     
EXEC USP_GetAllEntityListByEmployeeId @EmployeeId=2, @EntityStructureId=1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetAllEntityListByEmployeeId]
	@EmployeeId BIGINT = null,
	@EntityStructureId BIGINT = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				
				SELECT DISTINCT UPPER(LE.CompanyCode) + ' - ' + UPPER(LE.CompanyName) AS LegalEntityName, LE.LegalEntityId			
				FROM dbo.EntityStructureSetup ESS WITH (NOLOCK)
					JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON ESS.EntityStructureId = RMS.EntityStructureId
					JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND ISNULL(EUR.EmployeeId,0) = @EmployeeId AND RMS.IsDeleted = 0
					JOIN dbo.ManagementStructureLevel MSL WITH (NOLOCK) ON ESS.Level1Id = MSL.ID
					JOIN dbo.[LegalEntity] LE  WITH (NOLOCK) ON MSL.LegalEntityId =  LE.LegalEntityId
				WHERE ((ESS.IsDeleted = 0) AND ISNULL(EUR.EmployeeId,0) = @EmployeeId)
				ORDER BY LegalEntityName ASC
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAllEntityListByEmployeeId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '') + ''
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
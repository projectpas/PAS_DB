/*************************************************************           
 ** File:   [GetLegalEntityDetailsFromMSId]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to get Legal Entity From Entity Structure Id 
 ** Purpose:         
 ** Date:   06/03/2023      
          
 ** PARAMETERS: @EntityStructureId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/03/2023  Moin Bloch     Created
     
-- EXEC GetLegalEntityDetailsFromMSId 1
************************************************************************/
CREATE   PROCEDURE [dbo].[GetLegalEntityDetailsFromMSId]
@EntityStructureId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY

		--SELECT MSL.[LegalEntityId],LE.[Name]
		--FROM [dbo].[ManagementStructureLevel] MSL
		--INNER JOIN [dbo].[EntityStructureSetup] EST ON MSL.ID = EST.Level1Id
		--INNER JOIN [dbo].[RoleManagementStructure] RMS ON EST.EntityStructureId = RMS.EntityStructureId
		-- LEFT JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId
		--WHERE EST.EntityStructureId = @EntityStructureId
		--GROUP BY MSL.LegalEntityId,LE.[Name]

		SELECT LE.[LegalEntityId],LE.[Name]
		FROM [dbo].[ManagementStructureLevel] MSL
		INNER JOIN [dbo].[EntityStructureSetup] EST ON MSL.ID = EST.Level1Id
		INNER JOIN [dbo].[LegalEntity] LE ON MSL.LegalEntityId = LE.LegalEntityId
		INNER JOIN [dbo].[RoleManagementStructure] RMS ON EST.EntityStructureId = RMS.EntityStructureId
		WHERE RMS.RoleId IN (SELECT RoleId FROM [dbo].[RoleManagementStructure] WHERE EntityStructureId = @EntityStructureId)
		GROUP BY LE.[LegalEntityId],LE.[Name]

	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetLegalEntityDetailsFromMSId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@EntityStructureId, '') AS varchar(100))													 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END
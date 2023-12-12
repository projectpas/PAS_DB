CREATE PROCEDURE [dbo].[usp_GetMSSetupAuditHistoryData]
@EntityStructureId BIGINT
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN
				SELECT ESS.AuditEntityStructureId,ESS.EntityStructureId,					
					ESS.Level1Id,CAST(MSL1.Code AS VARCHAR(250)) + ' - ' + MSL1.[Description] AS Level1Name,
					ESS.Level2Id,CAST(MSL2.Code AS VARCHAR(250)) + ' - ' + MSL2.[Description] AS Level2Name,
					ESS.Level3Id,CAST(MSL3.Code AS VARCHAR(250)) + ' - ' + MSL3.[Description] AS Level3Name,
					ESS.Level4Id,CAST(MSL4.Code AS VARCHAR(250)) + ' - ' + MSL4.[Description] AS Level4Name,
					ESS.Level5Id,CAST(MSL5.Code AS VARCHAR(250)) + ' - ' + MSL5.[Description] AS Level5Name,
					ESS.Level6Id,CAST(MSL6.Code AS VARCHAR(250)) + ' - ' + MSL6.[Description] AS Level6Name,
					ESS.Level7Id,CAST(MSL7.Code AS VARCHAR(250)) + ' - ' + MSL7.[Description] AS Level7Name,
					ESS.Level8Id,CAST(MSL8.Code AS VARCHAR(250)) + ' - ' + MSL8.[Description] AS Level8Name,
					ESS.Level9Id,CAST(MSL9.Code AS VARCHAR(250)) + ' - ' + MSL9.[Description] AS Level9Name,
					ESS.Level10Id,CAST(MSL10.Code AS VARCHAR(250)) + ' - ' + MSL10.[Description] AS Level10Name,
					ESS.CreatedDate, ESS.UpdatedDate, ESS.CreatedBy, ESS.UpdatedBy,ESS.IsDeleted,ESS.IsActive
				FROM EntityStructureSetupAudit ESS WITH (NOLOCK)
					--LEFT JOIN LegalEntity LE on LE.LegalEntityId = ESS.Level1Id
					LEFT JOIN ManagementStructureLevel MSL1 WITH (NOLOCK) on ESS.Level1Id = MSL1.ID
					LEFT JOIN ManagementStructureLevel MSL2 WITH (NOLOCK) on ESS.Level2Id = MSL2.ID
					LEFT JOIN ManagementStructureLevel MSL3 WITH (NOLOCK) on ESS.Level3Id = MSL3.ID
					LEFT JOIN ManagementStructureLevel MSL4 WITH (NOLOCK) on ESS.Level4Id = MSL4.ID
					LEFT JOIN ManagementStructureLevel MSL5 WITH (NOLOCK) on ESS.Level5Id = MSL5.ID
					LEFT JOIN ManagementStructureLevel MSL6 WITH (NOLOCK) on ESS.Level6Id = MSL6.ID
					LEFT JOIN ManagementStructureLevel MSL7 WITH (NOLOCK) on ESS.Level7Id = MSL7.ID
					LEFT JOIN ManagementStructureLevel MSL8 WITH (NOLOCK) on ESS.Level8Id = MSL8.ID
					LEFT JOIN ManagementStructureLevel MSL9 WITH (NOLOCK) on ESS.Level9Id = MSL9.ID
					LEFT JOIN ManagementStructureLevel MSL10 WITH (NOLOCK) on ESS.Level10Id = MSL10.ID
				WHERE ESS.EntityStructureId = @EntityStructureId ORDER BY ESS.AuditEntityStructureId DESC;
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_GetMSSetupAuditHistoryData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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
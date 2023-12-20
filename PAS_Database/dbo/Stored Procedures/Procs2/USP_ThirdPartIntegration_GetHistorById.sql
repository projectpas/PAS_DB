CREATE     PROCEDURE [dbo].[USP_ThirdPartIntegration_GetHistorById]
@ThirdPartInegrationId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					t.ThirdPartInegrationId,
					t.LegalEntityId,
					t.CageCode,
					t.IntegrationIds,
					t.APIURL,
					t.SecretKey,
					t.AccessKey,
					   STUFF(
						(SELECT ', ' + convert(varchar(20), i.Description, 120)
						FROM dbo.[IntegrationPortal] i WITH (NOLOCK)
						where i.IntegrationPortalId in (SELECT Item FROM DBO.SPLITSTRING(t.IntegrationIds,','))
						FOR XML PATH (''))
						, 1, 1, '')  AS Description,
					--i.Description,
					l.Name,
					t.MasterCompanyId,
					t.CreatedBy,
					t.UpdatedBy,
					t.CreatedDate,
					t.UpdatedDate,
					t.IsActive,
					t.IsDeleted
				FROM [DBO].[ThirdPartInegrationAudit] t WITH (NOLOCK) 
				LEFT JOIN [DBO].[LegalEntity] l WITH (NOLOCK) ON t.LegalEntityId = l.LegalEntityId
				--LEFT JOIN [DBO].[ThirdPartInegration] i WITH (NOLOCK) ON t.[ThirdPartInegrationId] = l.[ThirdPartInegrationId]
				--LEFT JOIN [DBO].[IntegrationPortal] i WITH (NOLOCK) ON t.IntegrationIds = i.IntegrationPortalId
				WHERE t.[ThirdPartInegrationId] = @ThirdPartInegrationId ORDER BY t.ThirdPartInegrationAuditId DESC
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ThirdPartIntegration_GetHistorById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ThirdPartInegrationId, '') + ''
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
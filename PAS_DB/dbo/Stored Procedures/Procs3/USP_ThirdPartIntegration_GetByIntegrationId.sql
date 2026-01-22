
/*************************************************************           
 ** File:   [USP_ThirdPartIntegration_GetByIntegrationId]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used get intigrations data
 ** Purpose:         
 ** Date:   07/02/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/02/2023  Amit Ghediya    Created
     
-- EXEC USP_ThirdPartIntegration_GetByIntegrationId
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_ThirdPartIntegration_GetByIntegrationId]
@IntegrationId BIGINT,
@MastercompanyId INT,
@LegalEntityId BIGINT
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
					l.Name,
					t.MasterCompanyId,
					ISNULL(t.IsEmail,0) IsEmail
				FROM [DBO].[ThirdPartInegration] t WITH (NOLOCK) 
				LEFT JOIN [DBO].[LegalEntity] l WITH (NOLOCK) ON t.LegalEntityId = l.LegalEntityId
				LEFT JOIN [DBO].[IntegrationPortal] i WITH (NOLOCK) ON t.IntegrationIds = i.IntegrationPortalId
				WHERE t.[IntegrationIds] = @IntegrationId 
				  AND t.[MasterCompanyId] = @MastercompanyId 
				  AND t.[LegalEntityId] = @LegalEntityId
				  AND t.[IsActive] = 1
				  AND t.[IsDeleted] = 0;                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ThirdPartIntegration_GetByIntegrationId' 
              ,@ProcedureParameters VARCHAR(3000) = '@IntegrationId = ''' + CAST(ISNULL(@IntegrationId, '') as varchar(100))
			   + '@MastercompanyId = ''' + CAST(ISNULL(@MastercompanyId, '') as varchar(100)) 
			   + '@LegalEntityId = ''' + CAST(ISNULL(@LegalEntityId, '') as varchar(100))
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
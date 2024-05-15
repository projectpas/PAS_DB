/*************************************************************             
 ** File:   [USP_GetTransferTemplateList]             
 ** Author:   
 ** Description: This stored procedure is used to get WO Transfer Template List
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    15-05-2024    Moin Bloch   created
**************************************************************/  
-- =============================================
-- EXEC [dbo].[USP_GetTransferTemplateList] 47
-- =============================================
CREATE   PROCEDURE [dbo].[USP_GetTransferTemplateList]
@WorkflowId BIGINT=NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @Charges BIT = 0,@Tools BIT = 0,@Labor BIT = 0,@Material BIT = 0,@Directions BIT = 0,@Exclusions BIT = 0,@Measurements  BIT = 0,@Publications  BIT = 0;
		DECLARE @ChargesCount INT = 0,@EquipmentsCount INT = 0,@ExpertiseCount INT = 0,@MaterialsCount INT = 0,@DirectionsCount INT = 0,@ExclusionsCount INT = 0,@MeasurementsCount  INT = 0,@PublicationsCount INT = 0;

		SELECT  @ChargesCount = COUNT([WorkflowChargesListId]) FROM [dbo].[WorkflowChargesList] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND [IsDeleted] = 0;
				
		SELECT @EquipmentsCount = COUNT([WorkflowEquipmentListId]) FROM [dbo].[WorkflowEquipmentList] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND [IsDeleted] = 0;
				
		SELECT @ExpertiseCount = COUNT([WorkflowExpertiseListId]) FROM [dbo].[WorkflowExpertiseList] WITH(NOLOCK) WHERE  [WorkflowId] = @WorkflowId AND [IsDeleted] = 0;

		SELECT @MaterialsCount = COUNT([WorkflowMaterialListId]) FROM [dbo].[WorkflowMaterial] WITH(NOLOCK) WHERE  [WorkflowId] = @WorkflowId AND [IsDeleted] = 0;
		
		SELECT @DirectionsCount = COUNT([WorkflowDirectionId]) FROM [dbo].[WorkFlowDirection] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND [IsDeleted] = 0;
		
		SELECT @ExclusionsCount = COUNT([WorkflowExclusionId]) FROM [dbo].[WorkFlowExclusion] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND [IsDeleted] = 0;
		
		SELECT @MeasurementsCount = COUNT([WorkflowMeasurementId]) FROM [dbo].[WorkflowMeasurement] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND [IsDeleted] = 0;
		
		SELECT @PublicationsCount = COUNT([WorkflowPublicationsId]) FROM [dbo].[WorkflowPublications] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId AND [IsDeleted] = 0;
          			
		IF(@ChargesCount > 0)
		BEGIN
			SET @Charges = 1;
		END
		IF(@EquipmentsCount > 0)
		BEGIN
			SET @Tools = 1;
		END
		IF(@ExpertiseCount > 0)
		BEGIN
			SET @Labor = 1;
		END
		IF(@MaterialsCount > 0)
		BEGIN
			SET @Material = 1;
		END				
		IF(@DirectionsCount > 0)
		BEGIN
			SET @Directions = 1;
		END
		IF(@ExclusionsCount > 0)
		BEGIN
			SET @Exclusions = 1;
		END
		IF(@MeasurementsCount > 0)
		BEGIN
			SET @Measurements = 1;
		END
		IF(@PublicationsCount > 0)
		BEGIN
			SET @Publications = 1;
		END
				
		SELECT @Charges 'Charges',
		       @Tools 'Tools',
			   @Labor 'Labor',
			   @Material 'Material',
			   @Directions 'Directions',
			   @Exclusions 'Exclusions',
			   @Measurements 'Measurements',
			   @Publications 'Publications'
				
	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
	 PRINT 'ROLLBACK'			
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
         , @AdhocComments     VARCHAR(150)    = 'USP_GetTransferTemplateList' 			  
	     , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkflowId, '') AS VARCHAR(100))  
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
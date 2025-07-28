/*********************     
** Author:  <BHARGAV SALIYA >    
** Create date: <July-01-2025>    
** Description: <get Ai Integration Setting Data by mastercompanyId>    
    
EXEC [USP_GetPNLabelSettingData]   
**********************   
** Change History   
**********************     
** PR   Date              Author          Change Description    
** --   --------          -------         --------------------------------  
** 1	July-01-2025	BHARGAV SALIYA    Create
** 2	July-11-2025	BHARGAV SALIYA    Modified Two Fields YearId and MonthId

exec dbo.USP_GetPNLabelSettingData 1  
**********************/   
CREATE   PROCEDURE [dbo].[USP_Add_AiIntegrationSetting]
	@AiIntegrationSettingId BIGINT,
	@CreatedBy VARCHAR(50),
	@UpdatedBy VARCHAR(50),
	@MasterCompanyId int,
	@IsEnableDisableAIintegration BIT,
	@IsReviewRequired BIT,
	@IsAutoEmailSend BIT,
	@YearId bigint = 0,
	@MonthId bigint = 0,
	@PercentId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION;

		DECLARE @PercentValue DECIMAL = NULL;
		if(@PercentId > 0)
		begin
			(SELECT @PercentValue = PercentValue FROM [dbo].[Percent] WITH(NOLOCK) WHERE [PercentId] = @PercentId and [MasterCompanyId] = @MasterCompanyId and ISNULL(IsDeleted,0) = 0)
		end

		MERGE INTO dbo.AiIntegrationSetting AS TARGET
		USING (SELECT @AiIntegrationSettingId AS AiIntegrationSettingId, @MasterCompanyId AS MasterCompanyId) AS SOURCE
			ON TARGET.AiIntegrationSettingId = SOURCE.AiIntegrationSettingId 
			   AND TARGET.MasterCompanyId = SOURCE.MasterCompanyId
		WHEN MATCHED THEN
			UPDATE SET 
				TARGET.YearId = @YearId,
				TARGET.MonthId = @MonthId,
				TARGET.IsEnableDisableAIintegration = @IsEnableDisableAIintegration,
				TARGET.IsReviewRequired = @IsReviewRequired,
				TARGET.IsAutoEmailSend = @IsAutoEmailSend,
				TARGET.PercentId = @PercentId,
				TARGET.PercentValue = @PercentValue,
				TARGET.UpdatedDate = GETUTCDATE(),
				TARGET.UpdatedBy = @UpdatedBy
		WHEN NOT MATCHED BY TARGET THEN
			INSERT ([IsEnableDisableAIintegration], [IsReviewRequired], [IsAutoEmailSend],[PercentId],[PercentValue], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],[YearId], [MonthId])
			VALUES (@IsEnableDisableAIintegration, @IsReviewRequired, @IsAutoEmailSend,@PercentId,@PercentValue, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,@YearId, @MonthId);

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
		, @AdhocComments     VARCHAR(150)    = 'USP_Add_AiIntegrationSetting'   
		, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@AiIntegrationSettingId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@CreatedBy, '') as Varchar(100))+		
											  '@Parameter3 = '''+ CAST(ISNULL(@UpdatedBy, '') as Varchar(100))+		
											  '@Parameter4 = '''+ CAST(ISNULL(@MasterCompanyId, '') as Varchar(100))+		
											  '@Parameter5 = '''+ CAST(ISNULL(@IsEnableDisableAIintegration, '') as Varchar(100))+		
											  '@Parameter6 = '''+ CAST(ISNULL(@IsReviewRequired, '') as Varchar(100))+		
											  '@Parameter7 = '''+ CAST(ISNULL(@IsAutoEmailSend, '') as Varchar(100))+		
											  '@Parameter8 = '''+ CAST(ISNULL(@MasterCompanyId, '') as Varchar(100))+		
											  '@Parameter9 = '''+ CAST(ISNULL(@YearId, '') as Varchar(100))+		
											  '@Parameter10 = '''+ CAST(ISNULL(@MonthId, '') as Varchar(100))
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
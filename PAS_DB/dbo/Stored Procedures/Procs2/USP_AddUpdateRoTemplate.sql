/********************************************************************************   
** Author:     Amait Ghediya
** Create date:  05-05-2025
** Description: This SP is Used to save Ro Template   

**************************************************************************** 
** Change History 
****************************************************************************
** PR   Date		Author				Change Description  
** --   --------	-------				-----------------------------------
** 1    05-05-2025  Amit Ghediya	    Created

********************************************************************************/
CREATE    PROCEDURE [dbo].[USP_AddUpdateRoTemplate]      
(      
  @RepairOrderTemplateId BIGINT = 0,  
  @ItemMasterId BIGINT = 0,  
  @WorkPerformedId BIGINT = 0,  
  @CustomerId BIGINT = 0,
  @PublicationRecordId BIGINT =0,
  @VendorId BIGINT = 0,
  @Instruction VARCHAR(MAX) = '',
  @MasterCompanyId INT = 0,
  @CreatedBy VARCHAR(100)='',
  @UpdatedBy VARCHAR(100)='',
  @IsActive BIT = 0,
  @IsDeleted BIT = 0
)      
AS      
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  
		  DECLARE @RepairOrderTemplatesId BIGINT,
				  @IdCodeTypeId BIGINT,
				  @CurrentROTNumber AS BIGINT,
				  @ROTNumber AS VARCHAR(50); 

		  SELECT @IdCodeTypeId = [CodeTypeId] FROM [DBO].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'ROTemplate';

		  /*************** Prefixes ***************/		   			
		  IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
		  BEGIN
		  	DROP TABLE #tmpCodePrefixes
		  END
		  
		  CREATE TABLE #tmpCodePrefixes
		  (
		  		ID BIGINT NOT NULL IDENTITY, 
		  		CodePrefixId BIGINT NULL,
		  		CodeTypeId BIGINT NULL,
		  		CurrentNumber BIGINT NULL,
		  		CodePrefix VARCHAR(50) NULL,
		  		CodeSufix VARCHAR(50) NULL,
		  		StartsFrom BIGINT NULL,
		  )
		  
		  INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
		  SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
		  FROM dbo.CodePrefixes CP WITH(NOLOCK) 
		  JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
		  WHERE CT.CodeTypeId = @IdCodeTypeId
		  AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
		  
		  IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
		  BEGIN
		  	SELECT @CurrentROTNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) + 1 ELSE CAST(StartsFrom AS BIGINT) + 1 END 
		  	FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
		  				
		  	SET @ROTNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(
		  					@CurrentROTNumber,
		  					(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
		  					(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
		  END
		  /*****************End Prefixes*******************/	

		  IF(@RepairOrderTemplateId = 0)  
		  BEGIN  
				 INSERT INTO [dbo].[RepairOrderTemplate]  
				 ([RepairOrderTemplateNumber],[ItemMasterId],[WorkPerformedId],[CustomerId],[PublicationRecordId],[VendorId],[Instruction],
				  [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])  
			   VALUES(@ROTNumber,@ItemMasterId, @WorkPerformedId,@CustomerId,@PublicationRecordId,@VendorId,@Instruction, 
					@MasterCompanyId,@CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0);  
	
				UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @CurrentROTNumber WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId;

				SELECT @RepairOrderTemplatesId = SCOPE_IDENTITY();
		  END  
		  ELSE 
		  BEGIN  
			UPDATE [dbo].[RepairOrderTemplate] 
			SET 
				[ItemMasterId] = @ItemMasterId,
				[WorkPerformedId] = @WorkPerformedId,
				[CustomerId] = @CustomerId,
				[PublicationRecordId] = @PublicationRecordId,
				[VendorId] = @VendorId,
				[Instruction] = @Instruction,
				[UpdatedBy] = @UpdatedBy, 
				[UpdatedDate] = GETUTCDATE() 
			WHERE RepairOrderTemplateId = @RepairOrderTemplateId; 
		  END   
 END  
 COMMIT  TRANSACTION  
  
 END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateROTemplate'   
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') AS VARCHAR(100))  
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
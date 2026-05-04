/*************************************************************     
** Author:  <Amit Ghediya>    
** Create date: <01/04/2026>    
** Description: <This Proc Is used to Save Aircraft Publication GeneralInfo>    
    
Exec [USP_SaveAircraftPublication]   
**************************************************************   
** Change History   
**************************************************************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
   1    01/05/2026  Amit Ghediya		Created  
     
**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_SaveAircraftPublication]
    @tbl_AircraftPublicationType dbo.AircraftPublicationType READONLY
AS
BEGIN
    SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY 
	BEGIN TRANSACTION  
    BEGIN 
		
		DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50),@AircraftPublicationNum VARCHAR(30) = NULL;
		DECLARE @CurrentNo INT = 0;
		DECLARE @AircraftPublicationCodePrefix INT = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='AircraftPublicationNumber');
		DECLARE @MasterCompanyId INT = (SELECT [MasterCompanyId] FROM @tbl_AircraftPublicationType);
		SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @AircraftPublicationCodePrefix AND [MasterCompanyId] = @MasterCompanyId;

		IF EXISTS (SELECT 1 FROM @tbl_AircraftPublicationType WHERE AircraftPublicationId > 0)
		BEGIN
			-- UPDATE
			UPDATE AP
			SET 
				AP.PubDate = T.PubDate,
				AP.PublicationTypeId = T.PublicationTypeId,
				AP.PubNum = T.PubNum,
				AP.RevisionNum = T.RevisionNum,
				AP.AircraftSectionId = T.AircraftSectionId,
				AP.Subject = T.Subject,
				AP.PublishedById = T.PublishedById,
				AP.PublishedByRefId = T.PublishedByRefId,
				AP.PublishedByOthers = T.PublishedByOthers,
				AP.ComplianceCategoryId = T.ComplianceCategoryId,
				AP.ComplianceCategory = T.ComplianceCategory,
				AP.Timeframe = T.Timeframe,
				AP.PurposeReasonBackground = T.PurposeReasonBackground,
				AP.EntryDate = T.EntryDate,
				AP.VerifiedBy = T.VerifiedBy,
				AP.UpdatedBy = T.UpdatedBy,
				AP.UpdatedDate = GETUTCDATE()
			FROM [dbo].[AircraftPublication] AP WITH(NOLOCK)
			INNER JOIN @tbl_AircraftPublicationType T 
				ON AP.AircraftPublicationId = T.AircraftPublicationId;

			SELECT * 
			FROM AircraftPublication 
			WHERE AircraftPublicationId = (SELECT TOP 1 AircraftPublicationId FROM @tbl_AircraftPublicationType);
		END
		ELSE
		BEGIN
			IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
			BEGIN
				SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
				IF @CurrentNo > 0
				BEGIN
					SET @CurrentNo = @CurrentNo + 1;
					UPDATE [dbo].[CodePrefixes] 
					SET [CurrentNummber] = @CurrentNo
					WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				END
				ELSE
				BEGIN
					SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
					UPDATE [dbo].[CodePrefixes]
					SET [CurrentNummber] = @CurrentNo 
					WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
				END
				
				SET @AircraftPublicationNum = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
			END
			ELSE
			BEGIN
				SET @AircraftPublicationNum = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
			END
			-- INSERT
			INSERT INTO AircraftPublication
			(
				AircraftPublicationNumber,
				PubDate,
				PublicationTypeId,
				PubNum,
				RevisionNum,
				AircraftSectionId,
				Subject,
				PublishedById,
				PublishedByRefId,
				PublishedByOthers,
				ComplianceCategoryId,
				ComplianceCategory,
				Timeframe,
				PurposeReasonBackground,
				EntryDate,
				VerifiedBy,
				MasterCompanyId,
				CreatedBy,
				UpdatedBy,
				CreatedDate,
				UpdatedDate,
				IsActive,
				IsDeleted
			)
			SELECT
				@AircraftPublicationNum,
				PubDate,
				PublicationTypeId,
				PubNum,
				RevisionNum,
				AircraftSectionId,
				Subject,
				PublishedById,
				PublishedByRefId,
				PublishedByOthers,
				ComplianceCategoryId,
				ComplianceCategory,
				Timeframe,
				PurposeReasonBackground,
				EntryDate,
				VerifiedBy,
				MasterCompanyId,
				CreatedBy,
				UpdatedBy,
				GETUTCDATE(),
				GETUTCDATE(),
				IsActive,
				IsDeleted
			FROM @tbl_AircraftPublicationType;

			DECLARE @NewId BIGINT = SCOPE_IDENTITY();

			SELECT * FROM DBO.AircraftPublication WITH(NOLOCK) WHERE AircraftPublicationId = @NewId;
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
            , @AdhocComments     VARCHAR(150)    = 'USP_SaveAircraftPublication'     
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);    
	END CATCH   
 END
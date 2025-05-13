/*************************************************************           
 ** File:		 [USP_CreateLegalEntity]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create LegalEntity.
 ** Purpose:         
 ** Date:   09-May-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    09-May-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_CreateLegalEntity] @Name=N'LEGAL ENTITY',@AddressId=0,@PhoneNumber=N'98989892333',@FaxNumber=default,@FunctionalCurrencyId=2,@ReportingCurrencyId=2,
								 @IsBalancingEntity=1,@TagNames=N'',@CreatedBy=N'DANE PERK',@UpdatedBy=N'DANE PERK',@MasterCompanyId=1,@CompanyCode=N'LEGAL ENTITY CODE',
								 @CompanyName=N'COMPANY NAME',@IsAddressForBilling=1,@IsAddressForShipping=1,@Address1=N'ADDRESS LINE 1',@Address2=N'ADDRESS LINE 2',
								 @StateOrProvince=N'STATE',@City=N'CITY',@PostalCode=N'CODE',@CountryId=9,@IsPrintCheckNumber=0,@IsTurnOffMgmt=0,@InvoiceAddressPosition=1,
								 @InvoiceFaxPhonePosition=1,@TimeZoneId=7,@DoingLegalAs=Null,@PhoneExt=Null,@CageCode=Null,@FAALicense=Null,@EASALicense=Null,
								 @CAACLicense=Null,@TCCALicense=Null,@UKCAALicense=Null,@TaxId=Null,@LastLevel=0
**************************************************************/
Create   PROCEDURE [DBO].[USP_CreateLegalEntity]
@Name VARCHAR(100),
@CompanyCode VARCHAR(256),
@CompanyName VARCHAR(256),
@AddressId BIGINT, 
@PhoneNumber VARCHAR(30), 
@FaxNumber VARCHAR(30) = Null,
@FunctionalCurrencyId INT,
@ReportingCurrencyId INT ,
@TagNames VARCHAR(250),
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@MasterCompanyId INT,
@InvoiceAddressPosition INT,
@InvoiceFaxPhonePosition INT,
@IsAddressForBilling BIT,
@IsAddressForShipping BIT,
@IsBalancingEntity BIT,
@IsPrintCheckNumber BIT,
@IsTurnOffMgmt BIT,
@timeZoneId BIGINT,
@Address1 VARCHAR(50),
@Address2 VARCHAR(50) = Null,
@StateOrProvince VARCHAR(50),
@City VARCHAR(50),
@PostalCode VARCHAR(20),
@CountryId INT,
@DoingLegalAs VARCHAR(50) = Null,
@PhoneExt VARCHAR(20) = Null,
@CageCode VARCHAR(50) = Null,
@FAALicense VARCHAR(50) = Null,
@EASALicense  VARCHAR(100) = Null,
@CAACLicense VARCHAR(100) = Null,
@TCCALicense VARCHAR(100) = Null,
@UKCAALicense VARCHAR(200) = Null,
@TaxId VARCHAR(100) = Null,
@LastLevel BIT = Null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- Declare variables
		DECLARE @LegalEntityId BIGINT;
		DECLARE @LegalEntityCodeTypeId INT;
		DECLARE @CodePrefix NVARCHAR(50), @CodeSuffix NVARCHAR(50), @CurrentNo BIGINT = 0;
		DECLARE @ErrorMessage VARCHAR(MAX);

		-- Code Types Of CodePrefix	
		SELECT @LegalEntityCodeTypeId = [CodeTypeId] FROM [DBO].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Company';		
		SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @LegalEntityCodeTypeId AND [MasterCompanyId] = @MasterCompanyId;
		
		-- Tag Name
		IF OBJECT_ID(N'tempdb..#tmptagname') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmptagname    
		END   

		CREATE TABLE #tmptagname
		(        
			TagName VARCHAR(256) NULL    
		) 

		-- Error Msg
		IF OBJECT_ID(N'tempdb..#tmpmsg') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmpmsg    
		END   

		CREATE TABLE #tmpmsg
		(        
			msg VARCHAR(100) NULL    
		) 
/***************Start Save LegalEntity Details***************/		
		IF(@CodePrefix IS NOT NULL AND @CodePrefix <> '')
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntity] WITH(NOLOCK) WHERE [CompanyCode] = @CompanyCode AND [MasterCompanyId] = @MasterCompanyId)						
			BEGIN				
				IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntity] WITH(NOLOCK) WHERE [Name] = @Name AND MasterCompanyId = @MasterCompanyId)
				BEGIN
					
					SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
					IF (@CurrentNo > 0)
					BEGIN
						SET @CurrentNo = @CurrentNo + 1;
						UPDATE [DBO].[CodePrefixes] 
						SET [CurrentNummber] = @CurrentNo
						WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					END
					ELSE
					BEGIN
						SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0) FROM [DBO].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId);
						UPDATE [DBO].[CodePrefixes]
						SET [CurrentNummber] = @CurrentNo 
						WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
					END
					
					IF(ISNULL(@AddressId, 0) = 0)
					BEGIN
						INSERT INTO [DBO].[Address]( 
								[Line1],
								[Line2],
								[City],
								[StateOrProvince],
								[PostalCode],
								[CountryId],
								[MasterCompanyId], 
								[CreatedBy], 
								[UpdatedBy], 
								[CreatedDate], 
								[UpdatedDate], 
								[IsActive], 
								[IsDeleted])
							VALUES(
								@Address1,
								@Address2,
								@City,
								@StateOrProvince,						
								@PostalCode,
								@CountryId,
								@MasterCompanyId, 
								@CreatedBy, 
								@UpdatedBy, 
								GETUTCDATE(), 
								GETUTCDATE(), 
								1, 
								0)
 					
							SET @AddressId = SCOPE_IDENTITY();
					END

					IF(ISNULL(@LegalEntityId, 0) = 0)
					BEGIN
						INSERT INTO [DBO].[LegalEntity]( 
							[Name],
							[DoingLegalAs],
							[AddressId],
							[PhoneNumber],
							[FaxNumber],
							[FunctionalCurrencyId],
							[ReportingCurrencyId],
							[IsBalancingEntity],
							[CageCode],
							[FAALicense],
							[TaxId],
							[MasterCompanyId], 
							[CreatedBy], 
							[UpdatedBy], 
							[CreatedDate], 
							[UpdatedDate], 
							[IsActive], 
							[IsDeleted],
							[CompanyCode],
							[InvoiceAddressPosition],
							[InvoiceFaxPhonePosition],
							[LastLevel],
							[PhoneExt],
							[CompanyName],
							[IsAddressForBilling],
							[IsAddressForShipping],
							[TagName],
							[EASALicense],
							[CAACLicense],
							[TCCALicense],
							[TimeZoneId],
							[IsPrintCheckNumber],
							[IsTurnOffMgmt],
							[UKCAALicense])
						VALUES(
							@Name,
							@DoingLegalAs,
							@AddressId, 
							@PhoneNumber,
							@FaxNumber,
							@FunctionalCurrencyId,
							@ReportingCurrencyId ,
							@IsBalancingEntity,
							@CageCode,
							@FAALicense,
							@TaxId,
							@MasterCompanyId, 
							@CreatedBy, 
							@UpdatedBy, 
							GETUTCDATE(), 
							GETUTCDATE(), 
							1, 
							0,
							@CompanyCode,
							@InvoiceAddressPosition,
							@InvoiceFaxPhonePosition,
							@LastLevel,
							@PhoneExt,
							@CompanyName,
							@IsAddressForBilling,
							@IsAddressForShipping,
							@TagNames,
							@EASALicense,
							@CAACLicense,
							@TCCALicense,
							@timeZoneId,
							@IsPrintCheckNumber,
							@IsTurnOffMgmt,
							@UKCAALicense
							)						
		
						SET @LegalEntityId = SCOPE_IDENTITY();
					END
					IF(@LegalEntityId > 0)
					BEGIN
						
						IF(@IsAddressForShipping = 1)
						BEGIN
							
							EXEC [DBO].[USP_LegalEntityShippingAddress] @LegalEntityId,	0, @CompanyName, @Address1,	@Address2, @StateOrProvince, @City,	@PostalCode, @CountryId, 1, @CreatedBy, @UpdatedBy, @MasterCompanyId;
							
						END
						
						IF(@IsAddressForBilling = 1)
						BEGIN

							EXEC [DBO].[USP_LegalEntityBillingAddress] @LegalEntityId,	0, @CompanyName, @Address1,	@Address2, @StateOrProvince, @City,	@PostalCode, @CountryId, 1, @CreatedBy, @UpdatedBy, @MasterCompanyId;
							
						END

						IF(@TagNames IS NOT NULL AND @TagNames <> '' )
						BEGIN
							
							INSERT INTO #tmptagname	(TagName)
							SELECT	* FROM STRING_SPLIT(@TagNames, ',')

							INSERT INTO [DBO].[LegalEntityTagNameMapping] (
								TagName, LegalEntityId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,	IsActive, IsDeleted, MasterCompanyId)
							SELECT 
								TagName, @LegalEntityId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @MasterCompanyId
							FROM #tmptagname
							
						END

						EXEC [DBO].[UpdateLegalEntityColumnsWithId] @LegalEntityId;

					END
					ELSE
					BEGIN
						INSERT INTO #tmpmsg(msg) VALUES ('Legal Entity Id Should Be Greater Than 0.');					
					END				
				END
				ELSE
				BEGIN
					INSERT INTO #tmpmsg(msg) VALUES ('Legal Entity With Same Name Already Exists.');					
				END
			END
			ELSE
			BEGIN
				INSERT INTO #tmpmsg(msg) VALUES ('Legal Entity Code Already Exist.');				
			END
		END	
		ELSE
		BEGIN
			INSERT INTO #tmpmsg(msg) VALUES ('Code Prefix Not Available.');			
		END

/***************End Save LegalEntity Details***************/	

		IF EXISTS (SELECT 1 FROM #tmpmsg)
		BEGIN
			SELECT msg FROM #tmpmsg;			          
		END
		ELSE
		BEGIN			
			SELECT @LegalEntityId AS [LegalEntityId];
		END		
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateLegalEntity'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END
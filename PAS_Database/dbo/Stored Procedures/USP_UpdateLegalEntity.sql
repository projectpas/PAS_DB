/*************************************************************           
 ** File:		 [USP_UpdateLegalEntity]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Update LegalEntity.
 ** Purpose:         
 ** Date:   13-May-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    13-May-2025		Divyesh Kathiriya	Created    
    2    01-Oct-2025		Bhargav Saliya	    Add Field [IsCreaditRestriction].    
	3    09-Oct-2025        Bhargav Saliya      Added New Field [RestrictMessage]
 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateLegalEntity]
@LegalEntityId BIGINT,
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
@TimeZoneId BIGINT,
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
@LastLevel BIT = Null,
@LedgerId BIGINT = Null,
@IsCreaditRestriction BIT = Null,
@RestrictMessage VARCHAR(Max) = Null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- Declare variables			
		DECLARE @ErrorMessage VARCHAR(MAX);
		DECLARE @ShippingAddressId BIGINT;		
		DECLARE @BillingAddressId BIGINT;
		DECLARE @LegalEntityShippingAddressId BIGINT;
		DECLARE @LegalEntityBillingAddressId BIGINT;

		SELECT @ShippingAddressId = [ShippingAddressId] FROM [DBO].[LegalEntity] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId;
		SELECT @BillingAddressId = [BillingAddressId] FROM [DBO].[LegalEntity] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId;
		SELECT @LegalEntityShippingAddressId = [LegalEntityShippingAddressId] FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [AddressId] = @ShippingAddressId AND [LegalEntityId] = @LegalEntityId AND [MasterCompanyId] = @MasterCompanyId;
		SELECT @LegalEntityBillingAddressId = [LegalEntityBillingAddressId] FROM [DBO].[LegalEntityBillingAddress] WITH(NOLOCK) WHERE [AddressId] = @BillingAddressId AND [LegalEntityId] = @LegalEntityId AND [MasterCompanyId] = @MasterCompanyId;
		
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
		
/***************Start Update LegalEntity Details***************/		
		
		IF(ISNULL(@LegalEntityId, 0) > 0)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntity] WITH(NOLOCK) WHERE [CompanyCode] = @CompanyCode AND [MasterCompanyId] = @MasterCompanyId AND [LegalEntityId] != @LegalEntityId)
			BEGIN
				IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntity] WITH(NOLOCK) WHERE [Name] = @Name AND [MasterCompanyId] = @MasterCompanyId AND [LegalEntityId] != @LegalEntityId)
				BEGIN
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntity] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId)
					BEGIN
						IF EXISTS (SELECT 1 FROM [DBO].[Address] WITH(NOLOCK) WHERE [AddressId] = @AddressId)
						BEGIN	
							UPDATE [DBO].[LegalEntity]
							SET	[Name] = @Name,
								[DoingLegalAs] = @DoingLegalAs,								
								[PhoneNumber] = @PhoneNumber,
								[FaxNumber] = @FaxNumber,
								[FunctionalCurrencyId] = @FunctionalCurrencyId,
								[ReportingCurrencyId] = @ReportingCurrencyId,
								[IsBalancingEntity] = @IsBalancingEntity,
								[CageCode] = @CageCode,
								[FAALicense] = @FAALicense,
								[TaxId]= @TaxId,
								[UpdatedBy]= @UpdatedBy,							
								[UpdatedDate] = GETUTCDATE(), 							
								[CompanyCode] = @CompanyCode,
								[InvoiceAddressPosition] = @InvoiceAddressPosition,
								[InvoiceFaxPhonePosition] = @InvoiceFaxPhonePosition,
								[LastLevel] = @LastLevel,
								[PhoneExt] = @PhoneExt,
								[CompanyName] = @CompanyName,
								[IsAddressForBilling] = @IsAddressForBilling,
								[IsAddressForShipping] = @IsAddressForShipping,
								[LedgerId] = @LedgerId,
								[TagName] = @TagNames,
								[EASALicense] = @EASALicense,
								[CAACLicense] = @CAACLicense,
								[TCCALicense] = @TCCALicense,
								[TimeZoneId] = @TimeZoneId,
								[IsPrintCheckNumber] = @IsPrintCheckNumber,
								[IsTurnOffMgmt] = @IsTurnOffMgmt,
								[UKCAALicense] = @UKCAALicense,
								[IsCreaditRestriction] = @IsCreaditRestriction,
								[RestrictMessage] = @RestrictMessage
						  WHERE [LegalEntityId] = @LegalEntityId;

						  UPDATE [DBO].[Address]
						  SET [Line1] = @Address1,
							  [Line2] = @Address2,
							  [City] = @City,
							  [StateOrProvince] = @StateOrProvince,				
							  [PostalCode] = @PostalCode,
							  [CountryId] = @CountryId,
							  [UpdatedBy] = @UpdatedBy,
							  [UpdatedDate] = GETUTCDATE()
						  WHERE [AddressId] = @AddressId;        
        
							IF(ISNULL(@IsAddressForShipping, 0) = 1)
							BEGIN
							
								EXEC [DBO].[USP_LegalEntityShippingAddress] @LegalEntityId,	@LegalEntityShippingAddressId, @CompanyName, @Address1,	@Address2, @StateOrProvince, @City,	@PostalCode, @CountryId, 1, @CreatedBy, @UpdatedBy, @MasterCompanyId, @ShippingAddressId;
							
							END
						
							IF(ISNULL(@IsAddressForBilling, 0) = 1)
							BEGIN

								EXEC [DBO].[USP_LegalEntityBillingAddress] @LegalEntityId, @LegalEntityBillingAddressId, @CompanyName, @Address1, @Address2, @StateOrProvince, @City, @PostalCode, @CountryId, 1, @CreatedBy, @UpdatedBy, @MasterCompanyId, @BillingAddressId;
							
							END

							IF(@TagNames IS NOT NULL AND @TagNames <> '' )
							BEGIN

								DELETE FROM [DBO].[LegalEntityTagNameMapping]
								WHERE [LegalEntityId] = @LegalEntityId;
							
								INSERT INTO #tmptagname	(TagName)
								SELECT	* FROM STRING_SPLIT(@TagNames, ',')

								INSERT INTO [DBO].[LegalEntityTagNameMapping] (
									[TagName], [LegalEntityId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],	[IsActive], [IsDeleted], [MasterCompanyId])
								SELECT 
									TagName, @LegalEntityId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @MasterCompanyId
								FROM #tmptagname
							
						   END

						   EXEC [DBO].[UpdateLegalEntityColumnsWithId] @LegalEntityId;
								
						END						
						ELSE
						BEGIN
							INSERT INTO #tmpmsg(msg) VALUES ('Legal Entity Address Not Exist With These Details.');
						END
					END						
					ELSE
					BEGIN
						INSERT INTO #tmpmsg(msg) VALUES ('Legal Entity Does Not Exist With These Details.');
					END
				END
				ELSE
				BEGIN
					INSERT INTO #tmpmsg(msg) VALUES ('Legal Entity Name Already Exist.');
				END
			END
			ELSE
			BEGIN
				INSERT INTO #tmpmsg(msg) VALUES ('Legal Entity Code Already Exist.');
			END
		END
		ELSE
		BEGIN
			INSERT INTO #tmpmsg(msg) VALUES ('Legal Entity Id Should be Greater than 0.');
		END

/***************End Update LegalEntity Details***************/	

		IF EXISTS (SELECT 1 FROM #tmpmsg)
		BEGIN
			SELECT msg FROM #tmpmsg;			          
		END				
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateLegalEntity'
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
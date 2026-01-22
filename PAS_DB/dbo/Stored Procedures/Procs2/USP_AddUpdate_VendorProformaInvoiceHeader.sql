/*********************               
 ** File:   [USP_AddUpdate_VendorProformaInvoiceHeader]               
 ** Author:   Rajesh Gami      
 ** Description: To add / update the vendor proforma invoice     
 ** Purpose:             
 ** Date:   04-Dec-2024           
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **********************               
  ** Change History               
 **********************               
 ** S NO   Date            Author			Change Description                
 ** --   --------         -------			--------------------------------              
    1    04-Dec-2024	Rajesh Gami			Created 
	2    25-Dec-2024	Rajesh Gami			Added ControlNumber
	3    02-JAN-2025	Rajesh Gami			Remove Unwanted while update the Proforma
	3    02-JAN-2025	Bhargav Saliya		Append UTC time in InvoiceDate
  
**********************/    
CREATE   PROCEDURE [dbo].[USP_AddUpdate_VendorProformaInvoiceHeader]  
@VendorProformaInvoiceId BIGINT,  
@VendorId BIGINT,  
@VendorName VARCHAR(150),  
@VendorCode VARCHAR(150),  
@PaymentTermsId BIGINT,  
@StatusId INT,  
@ManagementStructureId INT, 
@MasterCompanyId BIGINT,  
@CreatedBy VARCHAR(50),  
@UpdatedBy  VARCHAR(50),  
@IsDeleted bit,
@PaymentMethodId BIGINT,
@EmployeeId BIGINT,
@IsEnforcePoRoApproval bit,
@EntryDate DATETIME2,
@InvoiceNumber VARCHAR(150),
@InvoiceDate DATETIME2,
@ReferenceNumber VARCHAR(150) = NULL,
@AccountingCalendarId BIGINT,
@CurrencyId BIGINT,
@ReferenceId BIGINT = NULL,
@ReferenceModuleId INT NULL,
@ReferenceModuleName VARCHAR(150) = NULL,
@IsPurchaseOrder BIT = 0
AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    

	DECLARE @ModuleID INT = 0;
	DECLARE @IdCodeTypeId BIGINT, @ControlCodeTypeId BIGINT;
	DECLARE @CurrentNumber AS BIGINT, @CurrentCTRLNumber AS BIGINT;
	DECLARE @VendorProformaInvoiceNo AS VARCHAR(50),@CTRLNumber AS VARCHAR(50);

	SET @InvoiceDate = DATEADD(SECOND, DATEDIFF(SECOND, CAST(GETUTCDATE() AS DATE), GETUTCDATE()), CAST(@InvoiceDate AS DATETIME2));
	SET @ModuleID = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE [ModuleName] = 'VendorProformaInvoice')
	SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'VendorProformaInvoice';
	SELECT @ControlCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'VendorProformaInvoiceCTRL';

	IF OBJECT_ID(N'tempdb..#tmpReturnVendorInvoiceId') IS NOT NULL    
     BEGIN    
      DROP TABLE #tmpReturnVendorInvoiceId   
     END   

	 CREATE TABLE #tmpReturnVendorInvoiceId([VendorProformaInvoiceId] [BIGINT] NULL)   
  
   IF(@VendorProformaInvoiceId = 0)  
   BEGIN  

	   /***** Prefixes *****/		   			
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
		FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
		WHERE CT.CodeTypeId = @IdCodeTypeId
		AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
		PRINT @IdCodeTypeId
		Select * from #tmpCodePrefixes
		IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
		BEGIN
			SET @CurrentNumber = (SELECT CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
			FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)
					
			SET @VendorProformaInvoiceNo = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
							@CurrentNumber,
							(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
							(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
		END
		/******End Prefixes******/	

		 /***** Prefixes : Control Number*******/		   			
		IF OBJECT_ID(N'tempdb..#tmpCodePrefixesCTRL') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCodePrefixesCTRL
		END
	
		CREATE TABLE #tmpCodePrefixesCTRL
		(
				ID BIGINT NOT NULL IDENTITY, 
				CodePrefixId BIGINT NULL,
				CodeTypeId BIGINT NULL,
				CurrentNumber BIGINT NULL,
				CodePrefix VARCHAR(50) NULL,
				CodeSufix VARCHAR(50) NULL,
				StartsFrom BIGINT NULL,
		)

		INSERT INTO #tmpCodePrefixesCTRL (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
		SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
		FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
		WHERE CT.CodeTypeId = @ControlCodeTypeId
		AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
		PRINT @ControlCodeTypeId
		IF (EXISTS (SELECT 1 FROM #tmpCodePrefixesCTRL WHERE CodeTypeId = @ControlCodeTypeId))
		BEGIN
			SET @CurrentCTRLNumber = (SELECT CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
			FROM #tmpCodePrefixesCTRL WHERE CodeTypeId = @ControlCodeTypeId)
					
			SET @CTRLNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
							@CurrentCTRLNumber,
							(SELECT CodePrefix FROM #tmpCodePrefixesCTRL WHERE CodeTypeId = @ControlCodeTypeId),
							(SELECT CodeSufix FROM #tmpCodePrefixesCTRL WHERE CodeTypeId = @ControlCodeTypeId)))
		END
		/******End Prefixes******/	
		PRINT @CurrentNumber
		PRINT @CurrentCTRLNumber
		IF(@CurrentNumber!='' OR @CurrentNumber!=NULL)
		BEGIN
			INSERT INTO [dbo].[VendorProformaInvoiceHeader]([VendorId] ,[VendorName] ,[VendorCode] ,[PaymentTermsId] ,[StatusId] ,[ManagementStructureId], [MasterCompanyId],  
								[CreatedBy], [CreatedDate],[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [PaymentMethodId], [EmployeeId], [IsEnforcePoRoApproval], VendorProformaInvoiceNo
								,[EntryDate], [InvoiceNumber], [InvoiceDate], [ReferenceNumber], [AccountingCalendarId], [CurrencyId],[ReferenceId],[ReferenceModuleId],ReferenceModuleName,IsPurchaseOrder,ControlNumber )  
			VALUES	(@VendorId , @VendorName, @VendorCode, @PaymentTermsId, @StatusId, @ManagementStructureId, @MasterCompanyId,  
					 @CreatedBy ,GETUTCDATE() , @CreatedBy ,GETUTCDATE() ,1 ,0, @PaymentMethodId, @EmployeeId, @IsEnforcePoRoApproval, @VendorProformaInvoiceNo,
					 @EntryDate, @InvoiceNumber, @InvoiceDate, @ReferenceNumber, @AccountingCalendarId, @CurrencyId,@ReferenceId,@ReferenceModuleId,@ReferenceModuleName,@IsPurchaseOrder,@CTRLNumber)  

			UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNumber AS BIGINT) + 1 WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId;
			
			IF(@CurrentCTRLNumber!='' OR @CurrentCTRLNumber!=NULL)
			BEGIN
				UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentCTRLNumber AS BIGINT) + 1 WHERE CodeTypeId = @ControlCodeTypeId AND MasterCompanyId = @MasterCompanyId;
			END
			
		END
  
		--SELECT @VendorProformaInvoiceId = MAX(VendorProformaInvoiceId) FROM [VendorProformaInvoiceHeader] WHERE [MasterCompanyId] = @MasterCompanyId
		SELECT @VendorProformaInvoiceId = SCOPE_IDENTITY();  
		INSERT INTO #tmpReturnVendorInvoiceId ([VendorProformaInvoiceId]) VALUES (@VendorProformaInvoiceId);    
		SELECT * FROM #tmpReturnVendorInvoiceId;    

		EXEC [USP_SaveNonPOInvoiceMSDetails] @ModuleID,@VendorProformaInvoiceId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy
  
   END  
   ELSE  
   BEGIN  
       UPDATE [dbo].[VendorProformaInvoiceHeader]  
               SET  [VendorId] = @VendorId
				   ,[VendorName] = @VendorName
				   ,[VendorCode] =@VendorCode
				   ,[PaymentTermsId] = @PaymentTermsId
				   ,[StatusId] = @StatusId
				   ,[ManagementStructureId] = @ManagementStructureId
				   ,[UpdatedBy] = @UpdatedBy  
				   ,[UpdatedDate] = GETUTCDATE()  
				   ,[IsDeleted] = @IsDeleted  
				   ,[PaymentMethodId] = @PaymentMethodId
				   ,[EntryDate] = @EntryDate
				   ,[InvoiceNumber] = @InvoiceNumber
				   ,[InvoiceDate] = @InvoiceDate
				   ,[AccountingCalendarId] = @AccountingCalendarId
				   ,[CurrencyId] = @CurrencyId
				   --,[ReferenceNumber] = @ReferenceNumber
				  -- ,[ReferenceId] = @ReferenceId
				  -- ,[ReferenceModuleId] = @ReferenceModuleId
				  --  ,ReferenceModuleName = @ReferenceModuleName
				  --,IsPurchaseOrder = @IsPurchaseOrder

              WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId;  

		INSERT INTO #tmpReturnVendorInvoiceId ([VendorProformaInvoiceId]) VALUES (@VendorProformaInvoiceId);    
		SELECT * FROM #tmpReturnVendorInvoiceId; 

		EXEC [USP_UpdateNonPOInvoiceMSDetails] @ModuleID,@VendorProformaInvoiceId,@ManagementStructureId,@UpdatedBy

   END     
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdate_VendorProformaInvoiceHeader'   
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@VendorProformaInvoiceId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END
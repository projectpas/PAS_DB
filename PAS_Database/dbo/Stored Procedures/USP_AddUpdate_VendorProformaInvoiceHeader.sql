
/*************************************************************               
 ** File:   [USP_AddUpdate_VendorProformaInvoiceHeader]               
 ** Author:   Rajesh Gami      
 ** Description: To add / update the vendor proforma invoice     
 ** Purpose:             
 ** Date:   04-Dec-2024           
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** S NO   Date            Author			Change Description                
 ** --   --------         -------			--------------------------------              
    1    04-Dec-2024	Rajesh Gami			Created    
  
**************************************************************/    
Create     PROCEDURE [dbo].[USP_AddUpdate_VendorProformaInvoiceHeader]  
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
@AccountingCalendarId BIGINT,
@CurrencyId BIGINT,
@ReferenceId BIGINT = NULL,
@ReferenceNumber VARCHAR(150) = NULL,
@ReferenceModuleId INT NULL,
@ReferenceModuleName VARCHAR(150) = NULL,
@IsPurchaseOrder bit = 0
AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    

	DECLARE @ModuleID INT = 0;
	DECLARE @IdCodeTypeId BIGINT;
	DECLARE @CurrentProformaInvoiceNumber AS BIGINT;
	DECLARE @ProformaInvoiceNumber AS VARCHAR(50);

	SET @ModuleID = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE [ModuleName] = 'VendorProformaInvoice')
	SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'VendorProformaInvoice';

	IF OBJECT_ID(N'tempdb..#tmpReturnVendorProformaInvoiceId') IS NOT NULL    
     BEGIN    
      DROP TABLE #tmpReturnVendorProformaInvoiceId   
     END   

	 CREATE TABLE #tmpReturnVendorProformaInvoiceId([VendorProformaInvoiceId] [BIGINT] NULL)   
  
   IF(@VendorProformaInvoiceId = 0)  
   BEGIN  

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
		FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
		WHERE CT.CodeTypeId = @IdCodeTypeId
		AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

		IF (EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId))
		BEGIN
			SELECT @CurrentProformaInvoiceNumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
			FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					
			SET @ProformaInvoiceNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
							@CurrentProformaInvoiceNumber,
							(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
							(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
		END
		/*****************End Prefixes*******************/	
  
		IF(@CurrentProformaInvoiceNumber!='' OR @CurrentProformaInvoiceNumber!=NULL)
		BEGIN
			INSERT INTO [dbo].[VendorProformaInvoiceHeader]([VendorId] ,[VendorName] ,[VendorCode] ,[PaymentTermsId] ,[StatusId] ,[ManagementStructureId], [MasterCompanyId],  
								[CreatedBy], [CreatedDate],[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [PaymentMethodId], [EmployeeId], [IsEnforcePoRoApproval], [VendorProformaInvoiceNo]
								,[EntryDate], [InvoiceNumber], [InvoiceDate], [AccountingCalendarId], [CurrencyId],[ReferenceId],[ReferenceModuleId],ReferenceNumber,ReferenceModuleName,IsPurchaseOrder)  
			VALUES	(@VendorId , @VendorName, @VendorCode, @PaymentTermsId, @StatusId, @ManagementStructureId, @MasterCompanyId,  
					 @CreatedBy ,GETUTCDATE() , @CreatedBy ,GETUTCDATE() ,1 ,0, @PaymentMethodId, @EmployeeId, @IsEnforcePoRoApproval, @ProformaInvoiceNumber,
					 @EntryDate, @InvoiceNumber, @InvoiceDate,  @AccountingCalendarId, @CurrencyId,@ReferenceId,@ReferenceModuleId,@ReferenceNumber,@ReferenceModuleName,@IsPurchaseOrder)  

			UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentProformaInvoiceNumber AS BIGINT) + 1 WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId;
		END
  
		SELECT @VendorProformaInvoiceId = SCOPE_IDENTITY();  
		INSERT INTO #tmpReturnVendorProformaInvoiceId ([VendorProformaInvoiceId]) VALUES (@VendorProformaInvoiceId);    
		SELECT * FROM #tmpReturnVendorProformaInvoiceId;    

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
				   ,[ReferenceId] = @ReferenceId
				   ,ReferenceNumber = @ReferenceNumber
				   ,[ReferenceModuleId] = @ReferenceModuleId
				   ,ReferenceModuleName = @ReferenceModuleName
				   ,IsPurchaseOrder = @IsPurchaseOrder

              WHERE [VendorProformaInvoiceId] = @VendorProformaInvoiceId;  

		INSERT INTO #tmpReturnVendorProformaInvoiceId ([VendorProformaInvoiceId]) VALUES (@VendorProformaInvoiceId);    
		SELECT * FROM #tmpReturnVendorProformaInvoiceId; 

		EXEC [USP_UpdateNonPOInvoiceMSDetails] @ModuleID,@VendorProformaInvoiceId,@ManagementStructureId,@UpdatedBy

   END     
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
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
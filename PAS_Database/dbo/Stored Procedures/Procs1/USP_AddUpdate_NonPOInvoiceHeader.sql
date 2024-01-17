/*************************************************************               
 ** File:   [USP_AddUpdate_NonPOInvoiceHeader]               
 ** Author:   Shrey Chandegara      
 ** Description: to add / update the vendor credit memo     
 ** Purpose:             
 ** Date:   13-September-2023           
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** S NO   Date            Author			Change Description                
 ** --   --------         -------			--------------------------------              
    1    22-June-2022	Shrey Chandegara			Created    
    2    14-SEP-2023	Devendra Shekh			added paymentMethodId    
    3    26-SEP-2023	Devendra Shekh			added employeeid    and IsEnforceNonPoApproval
    4    03-OCT-2023	Devendra Shekh			added NPONum for insert
    5    11-OCT-2023	Devendra Shekh			added new columns for insert
    6    26-OCT-2023	Devendra Shekh			added new columns for insert
	7    11-JAN-2024	Moin Bloch   			added new columns ReferenceId,ReferenceModuleId
	7    16-JAN-2024	Moin Bloch   			added Updated by on Update Header
  
**************************************************************/    
CREATE   PROCEDURE [dbo].[USP_AddUpdate_NonPOInvoiceHeader]  
@NonPOInvoiceId BIGINT,  
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
@IsEnforceNonPoApproval bit,
@EntryDate DATETIME2,
@InvoiceNumber VARCHAR(150),
@InvoiceDate DATETIME2,
@PONumber VARCHAR(150) = NULL,
@AccountingCalendarId BIGINT,
@CurrencyId BIGINT,
@ReferenceId BIGINT = NULL,
@ReferenceModuleId INT NULL
AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    

	DECLARE @ModuleID INT = 0;
	DECLARE @IdCodeTypeId BIGINT;
	DECLARE @CurrentNPONumber AS BIGINT;
	DECLARE @NPONumber AS VARCHAR(50);

	SET @ModuleID = (SELECT [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH (NOLOCK) WHERE [ModuleName] = 'NonPOInvoiceHeader')
	SELECT @IdCodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'NonPOInvoice';

	IF OBJECT_ID(N'tempdb..#tmpReturnNonPOInvoiceId') IS NOT NULL    
     BEGIN    
      DROP TABLE #tmpReturnNonPOInvoiceId   
     END   

	 CREATE TABLE #tmpReturnNonPOInvoiceId([NonPOInvoiceId] [BIGINT] NULL)   
  
   IF(@NonPOInvoiceId = 0)  
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
			SELECT @CurrentNPONumber = CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
			FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId
					
			SET @NPONumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
							@CurrentNPONumber,
							(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId),
							(SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @IdCodeTypeId)))
		END
		/*****************End Prefixes*******************/	
  
		IF(@CurrentNPONumber!='' OR @CurrentNPONumber!=NULL)
		BEGIN
			INSERT INTO [dbo].[NonPOInvoiceHeader]([VendorId] ,[VendorName] ,[VendorCode] ,[PaymentTermsId] ,[StatusId] ,[ManagementStructureId], [MasterCompanyId],  
								[CreatedBy], [CreatedDate],[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [PaymentMethodId], [EmployeeId], [IsEnforceNonPoApproval], [NPONumber]
								,[EntryDate], [InvoiceNumber], [InvoiceDate], [PONumber], [AccountingCalendarId], [CurrencyId],[ReferenceId],[ReferenceModuleId] )  
			VALUES	(@VendorId , @VendorName, @VendorCode, @PaymentTermsId, @StatusId, @ManagementStructureId, @MasterCompanyId,  
					 @CreatedBy ,GETUTCDATE() , @CreatedBy ,GETUTCDATE() ,1 ,0, @PaymentMethodId, @EmployeeId, @IsEnforceNonPoApproval, @NPONumber,
					 @EntryDate, @InvoiceNumber, @InvoiceDate, @PONumber, @AccountingCalendarId, @CurrencyId,@ReferenceId,@ReferenceModuleId)  

			UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNPONumber AS BIGINT) + 1 WHERE CodeTypeId = @IdCodeTypeId AND MasterCompanyId = @MasterCompanyId;
		END
  
		--SELECT @NonPOInvoiceId = MAX(NonPOInvoiceId) FROM [NonPOInvoiceHeader] WHERE [MasterCompanyId] = @MasterCompanyId
		SELECT @NonPOInvoiceId = SCOPE_IDENTITY();  
		INSERT INTO #tmpReturnNonPOInvoiceId ([NonPOInvoiceId]) VALUES (@NonPOInvoiceId);    
		SELECT * FROM #tmpReturnNonPOInvoiceId;    

		EXEC [USP_SaveNonPOInvoiceMSDetails] @ModuleID,@NonPOInvoiceId,@ManagementStructureId,@MasterCompanyId,@UpdatedBy
  
   END  
   ELSE  
   BEGIN  
       UPDATE [dbo].[NonPOInvoiceHeader]  
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
				   ,[PONumber] = @PONumber
				   ,[ReferenceId] = @ReferenceId
				   ,[ReferenceModuleId] = @ReferenceModuleId

              WHERE [NonPOInvoiceId] = @NonPOInvoiceId;  

		INSERT INTO #tmpReturnNonPOInvoiceId ([NonPOInvoiceId]) VALUES (@NonPOInvoiceId);    
		SELECT * FROM #tmpReturnNonPOInvoiceId; 

		EXEC [USP_UpdateNonPOInvoiceMSDetails] @ModuleID,@NonPOInvoiceId,@ManagementStructureId,@UpdatedBy

   END     
                  
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdate_NonPOInvoiceHeader'   
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@NonPOInvoiceId, '') AS VARCHAR(100)) 
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
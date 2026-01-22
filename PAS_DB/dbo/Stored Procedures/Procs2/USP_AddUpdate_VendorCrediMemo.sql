/*************************************************************             
 ** File:   [USP_AddUpdate_VendorCrediMemo]             
 ** Author:   Devendra Shekh    
 ** Description: to add / update the vendor credit memo   
 ** Purpose:           
 ** Date:   22-June-2023         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    22-June-2022	Devendra Shekh		Created  
    2    21-July-2022	Devendra Shekh		UpdateVendorCreditmemo issue resolved  
    3    07-Nov-2023	Devendra Shekh		added new columns for add/update 
    4    15-March-2024	Devendra Shekh		added new columns for add/@VendorCreditMemoTypeId,@CustomerCreditPaymentDetailId

**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_AddUpdate_VendorCrediMemo]
@VendorCreditMemoId BIGINT,
@VendorCreditMemoNumber varchar(50),
@VendorRMAId BIGINT = NULL,
@RMANum varchar(50),
@VendorCreditMemoStatusId INT,
@CurrencyId BIGINT = NULL,
@OriginalAmt decimal(18,0) = NULL,
@ApplierdAmt decimal(18,0) = NULL,
@RefundAmt decimal(18,0) = NULL,
@RefundDate datetime,
@CreatedBy varchar(50),
@UpdatedBy  varchar(50),
@IsDeleted bit,
@MasterCompanyId BIGINT,
@VendorId BIGINT = NULL,
@OpenDate DATETIME2 = NULL,
@Notes VARCHAR(MAX) = NULL,
@RequestedBy BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				
				IF OBJECT_ID(N'tempdb..#tmpReturnVendorCreditMemoId') IS NOT NULL  
				BEGIN  
					DROP TABLE #tmpReturnVendorCreditMemoId 
				END  
				CREATE TABLE #tmpReturnVendorCreditMemoId([VendorCreditMemoId] [BIGINT] NULL)  

				IF(@VendorCreditMemoId = 0)
				BEGIN

       				INSERT INTO [dbo].[VendorCreditMemo]([VendorCreditMemoNumber] ,[VendorRMAId] ,[RMANum] ,[VendorCreditMemoStatusId] ,[CurrencyId] ,[OriginalAmt] ,[ApplierdAmt] , [RefundAmt], [RefundDate], [MasterCompanyId],
					   [CreatedBy], [CreatedDate],[UpdatedBy] ,[UpdatedDate] ,[IsActive] , [IsDeleted], [VendorId], [OpenDate], [Notes], [RequestedBy])
					VALUES(@VendorCreditMemoNumber , @VendorRMAId, @RMANum, @VendorCreditMemoStatusId, @CurrencyId, @OriginalAmt, @ApplierdAmt, @RefundAmt, @RefundDate, @MasterCompanyId,
					   @CreatedBy ,GETUTCDATE() , @CreatedBy ,GETUTCDATE() ,1 ,0, @VendorId, @OpenDate, @Notes, @RequestedBy)

					SET  @VendorCreditMemoId = @@IDENTITY;  
					INSERT INTO #tmpReturnVendorCreditMemoId ([VendorCreditMemoId]) VALUES (@VendorCreditMemoId);  
					SELECT * FROM #tmpReturnVendorCreditMemoId;  
				END
				ELSE
				BEGIN
					DECLARE @EmployeeId BIGINT = 0;
					SET @EmployeeId = (SELECT [RequestedBy] FROM [DBO].[VendorCreditMemo] WITH(NOLOCK) WHERE VendorCreditMemoId = @VendorCreditMemoId)
					IF(ISNULL(@EmployeeId, 0) <> 0)
					BEGIN
						SET @EmployeeId = @EmployeeId
					END
					ELSE
					BEGIN
						SET @EmployeeId = @RequestedBy
					END

					UPDATE [dbo].[VendorCreditMemo]
					SET 
						[VendorCreditMemoStatusId] = @VendorCreditMemoStatusId
					   ,[OriginalAmt] = @OriginalAmt
					   ,[ApplierdAmt] = @ApplierdAmt
					   ,[RefundAmt] = @RefundAmt
					   ,[RefundDate] = @RefundDate
					   ,[UpdatedBy] = @CreatedBy
					   ,[UpdatedDate] = GETUTCDATE()
					   ,[IsDeleted] = @IsDeleted
					   ,[OpenDate] = @OpenDate
					   ,[Notes] = @Notes
					   ,[RequestedBy] = @EmployeeId
					WHERE VendorCreditMemoId= @VendorCreditMemoId

					INSERT INTO #tmpReturnVendorCreditMemoId ([VendorCreditMemoId]) VALUES (@VendorCreditMemoId);  
					SELECT * FROM #tmpReturnVendorCreditMemoId;  
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
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdate_VendorCrediMemo' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorCreditMemoId, '') + ''
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
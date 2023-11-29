
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
    1    22-June-2022 Devendra Shekh   Created  
    1    21-July-2022 Devendra Shekh   UpdateVendorCreditmemo issue resolved  

**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_AddUpdate_VendorCrediMemo]
@VendorCreditMemoId bigint,
@VendorCreditMemoNumber varchar(50),
@VendorRMAId bigint = NULL,
@RMANum varchar(50),
@VendorCreditMemoStatusId INT,
@CurrencyId bigint = NULL,
@OriginalAmt decimal(18,0) = NULL,
@ApplierdAmt decimal(18,0) = NULL,
@RefundAmt decimal(18,0) = NULL,
@RefundDate datetime,
@CreatedBy varchar(50),
@UpdatedBy  varchar(50),
@IsDeleted bit,
@MasterCompanyId bigint,
@VendorId bigint = NULL

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

			If(@VendorCreditMemoId = 0)
			BEGIN
			--PRINT '1'

			  IF OBJECT_ID(N'tempdb..#tmpReturnVendorCreditMemoId') IS NOT NULL  
			  BEGIN  
			   DROP TABLE #tmpReturnVendorCreditMemoId 
			  END  
  
			  CREATE TABLE #tmpReturnVendorCreditMemoId([VendorCreditMemoId] [bigint] NULL)  

       			INSERT INTO [dbo].[VendorCreditMemo]([VendorCreditMemoNumber] ,[VendorRMAId] ,[RMANum] ,[VendorCreditMemoStatusId] ,[CurrencyId] ,[OriginalAmt] ,[ApplierdAmt] , [RefundAmt], [RefundDate], [MasterCompanyId],
				   [CreatedBy], [CreatedDate],[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted], [VendorId])
				VALUES(@VendorCreditMemoNumber , @VendorRMAId, @RMANum, @VendorCreditMemoStatusId, @CurrencyId, @OriginalAmt, @ApplierdAmt, @RefundAmt, @RefundDate, @MasterCompanyId,
				   @CreatedBy ,GETUTCDATE() , @CreatedBy ,GETUTCDATE() ,1 ,0, @VendorId)

				SET  @VendorCreditMemoId = @@IDENTITY;  
				INSERT INTO #tmpReturnVendorCreditMemoId ([VendorCreditMemoId]) VALUES (@VendorCreditMemoId);  
				SELECT * FROM #tmpReturnVendorCreditMemoId;  

			END
			else
			Begin

			    UPDATE [dbo].[VendorCreditMemo]
                SET 
                    --[VendorRMAId] = @VendorRMAId
                   --,[RMANum] = @RMANum
                   [VendorCreditMemoStatusId] = @VendorCreditMemoStatusId
                   --,[CurrencyId] = @CurrencyId
                   ,[OriginalAmt] = @OriginalAmt
                   ,[ApplierdAmt] = @ApplierdAmt
                   ,[RefundAmt] = @RefundAmt
                   ,[RefundDate] = @RefundDate
                   ,[UpdatedBy] = @CreatedBy
                   ,[UpdatedDate] = GETUTCDATE()
                   ,[IsDeleted] = @IsDeleted
				   --,[VendorId] = [VendorId]
              WHERE VendorCreditMemoId= @VendorCreditMemoId
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